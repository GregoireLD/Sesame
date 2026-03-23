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
        useLegacyScheme: Bool = false
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
        if let address = accessCode.address {
            items.append(URLQueryItem(name: "address", value: address))
        }

        // code is optional — only include if present
        if let plainCode {
            items.append(URLQueryItem(name: "code", value: plainCode))
        }

        if includeCoordinates,
           let lat = accessCode.latitude,
           let lon = accessCode.longitude {
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

        if useLegacyScheme {
            components.queryItems = items
            return components.url
        } else {
            var fragmentComponents = URLComponents()
            fragmentComponents.queryItems = items
            guard let encodedQuery = fragmentComponents.percentEncodedQuery else { return nil }
            let urlString = "https://sesame-app.com/share#\(encodedQuery)"
            return URL(string: urlString)
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
        // For https:// Universal Links, parameters are in the fragment
        // For sesame:// legacy scheme, parameters are in query items
        let paramString: String?
        if url.scheme == "https" {
            paramString = url.fragment
        } else {
            paramString = url.query
        }

        guard let paramString,
              !paramString.isEmpty else { return nil }

        // Parse the parameter string manually
        var paramDict: [String: String] = [:]
        paramString.split(separator: "&").forEach { pair in
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
}
