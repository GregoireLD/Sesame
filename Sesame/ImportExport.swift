//
//  ImportExport.swift
//  Sesame
//
//  Created by Greg on 2026-03-16.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import MapKit

// MARK: - ParsedImport

struct ParsedImport {
    let label: String
    let address: String?
    let code: String?
    let radiusMeters: Double?
    let locationDetails: String?
    let comment: String?
    let isSilenced: Bool
    let latitude: Double?
    let longitude: Double?
}

// MARK: - ImportExport

struct ImportExport {

    // MARK: - Export: URL Generation

    static func url(
        for accessCode: AccessCode,
        includeRadius: Bool = false,
        includeLocationDetails: Bool = false,
        includeComment: Bool = false,
        includeCoordinates: Bool = true,
        useLegacyScheme: Bool = false,
        usePlainFragment: Bool = false
    ) -> URL? {
        guard let label = accessCode.label else { return nil }

        // code is now optional
        let plainCode: String?
        if let storedCode = accessCode.code {
            switch CryptoManager.decrypt(storedCode) {
            case .success(let plain), .legacyPlainText(let plain):
                plainCode = plain
            default:
                return nil
            }
        } else {
            plainCode = nil
        }

        var components = URLComponents()
        if useLegacyScheme {
            components.scheme = "sesame"
            components.host = "import"
        } else {
            components.scheme = "https"
            components.host = "sesame-app.com"
            components.path = "/share"
        }

        var items: [URLQueryItem] = [
            URLQueryItem(name: "v", value: "1"),
            URLQueryItem(name: "label", value: label),
        ]

        // address is optional — only include if present
        if let address = accessCode.decryptedAddress {
            items.append(URLQueryItem(name: "address", value: address))
        }

        // code is optional — only include if present
        if let plainCode {
            items.append(URLQueryItem(name: "code", value: plainCode))
        }

        if includeCoordinates,
           let lat = accessCode.decryptedLatitude,
           let lon = accessCode.decryptedLongitude {
            items.append(URLQueryItem(name: "lat", value: String(format: "%.5f", lat)))
            items.append(URLQueryItem(name: "lon", value: String(format: "%.5f", lon)))
        }

        if includeRadius, let radius = accessCode.radiusMeters {
            items.append(URLQueryItem(name: "radius", value: String(radius)))
        }

        if includeLocationDetails, let locationDetails = accessCode.locationDetails {
            switch CryptoManager.decrypt(locationDetails) {
            case .success(let plain), .legacyPlainText(let plain):
                if !plain.isEmpty {
                    items.append(URLQueryItem(name: "details", value: plain))
                }
            default:
                break
            }
        }

        if includeComment, let comment = accessCode.comment {
            switch CryptoManager.decrypt(comment) {
            case .success(let plain), .legacyPlainText(let plain):
                if !plain.isEmpty {
                    items.append(URLQueryItem(name: "comment", value: plain))
                }
            default:
                break
            }
        }

        // Build the parameter string
        var fragmentComponents = URLComponents()
        fragmentComponents.queryItems = items
        guard var queryString = fragmentComponents.percentEncodedQuery else { return nil }
        // URLComponents leaves '+' unescaped (it is legal in an RFC 3986 query),
        // but form-style parsers decode '+' as a space — Android's URLDecoder
        // among them. Escape it so the payload is unambiguous everywhere.
        // Safe: '+' can never appear inside a %XX escape sequence, and the CRC
        // below is computed over the escaped string, i.e. the actual wire bytes.
        queryString = queryString.replacingOccurrences(of: "+", with: "%2B")

        // Append CRC32, then encode
        let queryStringWithCRC = queryString + "&crc32=\(computeCRC32(queryString))"
        let encodedParams = usePlainFragment
            ? queryStringWithCRC
            : base64URLEncode(queryStringWithCRC)
        
        // Apply parameters based on scheme
        if useLegacyScheme {
            // For sesame://, use fragment (to respect usePlainFragment)
            guard let base = components.url?.absoluteString else { return nil }
            return URL(string: "\(base)#\(encodedParams)")
        } else {
            // For https://, use fragment (Universal Link standard)
            guard let base = components.url?.absoluteString else { return nil }
            return URL(string: "\(base)#\(encodedParams)")
        }
    }

    // MARK: - Export: QR Image Generation

    static func image(for url: URL, size: CGFloat = 300) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(url.absoluteString.utf8)
        filter.correctionLevel = "M"

        guard let ciImage = filter.outputImage else { return nil }

        let scaleX = size / ciImage.extent.width
        let scaleY = size / ciImage.extent.height
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - Import: URL Parsing

    static func parse(url: URL) -> ParsedImport? {
        // Parameters can be in fragment (for both https:// and sesame://)
        // or in query string (for legacy sesame:// URLs)
        let paramString: String?
        
        // First check for fragment (new format for both schemes)
        if let fragment = url.fragment, !fragment.isEmpty {
            // Try Base64URL decode first, fall back to plain if it fails
            if let decoded = base64URLDecode(fragment),
               decoded.contains("=") {
                paramString = decoded
            } else {
                // Plain text fallback
                paramString = fragment
            }
        }
        // Fall back to query string (legacy sesame:// format)
        else if let query = url.query, !query.isEmpty {
            paramString = query
        }
        else {
            paramString = nil
        }

        guard let paramString, !paramString.isEmpty else { return nil }

        // Verify CRC32 if present, strip it before parsing
        let payloadString: String
        if let crcRange = paramString.range(of: "&crc32=", options: .backwards) {
            let candidate = String(paramString[crcRange.upperBound...])
            let payload   = String(paramString[..<crcRange.lowerBound])
            guard candidate.count == 8,
                  candidate.allSatisfy({ $0.isHexDigit }),
                  computeCRC32(payload) == candidate
            else { return nil }
            payloadString = payload
        } else {
            payloadString = paramString
        }

        // Parse the parameter string manually
        var paramDict: [String: String] = [:]
        payloadString.split(separator: "&").forEach { pair in
            let parts = pair.split(separator: "=", maxSplits: 1)
            if parts.count == 2,
               let key = parts[0].removingPercentEncoding,
               let value = parts[1].removingPercentEncoding {
                paramDict[key] = value
            }
        }

        func param(_ name: String) -> String? { paramDict[name] }

        let version = param("v") ?? "1"
        guard version == "1" else { return nil }

        guard let label = param("label"),
              !label.isEmpty else { return nil }

        return ParsedImport(
            label: label,
            address: param("address"),
            code: param("code"),
            radiusMeters: param("radius").flatMap { Double($0) },
            locationDetails: param("details"),
            comment: param("comment"),
            isSilenced: param("silenced") == "1",
            latitude: param("lat").flatMap { Double($0) },
            longitude: param("lon").flatMap { Double($0) }
        )
    }
    
    // MARK: - Tools

    private static let crc32Table: [UInt32] = (0..<256).map { i -> UInt32 in
        (0..<8).reduce(UInt32(i)) { c, _ in (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1) }
    }

    private static func computeCRC32(_ string: String) -> String {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in Data(string.utf8) {
            crc = crc32Table[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8)
        }
        return String(format: "%08x", crc ^ 0xFFFFFFFF)
    }

    private static func base64URLEncode(_ string: String) -> String {
        Data(string.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func base64URLDecode(_ string: String) -> String? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        // Re-add padding
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        guard let data = Data(base64Encoded: base64) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
