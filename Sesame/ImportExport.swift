//
//  QRCodeGenerator.swift
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
    let address: String
    let code: String
    let radiusMeters: Double?
    let locationDetails: String?
    let comment: String?
    let isSilenced: Bool
}

// MARK: - ImportExport

struct ImportExport {

    // MARK: - Export: URL Generation

    static func url(
        for accessCode: AccessCode,
        includeRadius: Bool = false,
        includeLocationDetails: Bool = false,
        includeComment: Bool = false
    ) -> URL? {
        guard let label = accessCode.label,
              let code = accessCode.code,
              let address = accessCode.address else { return nil }

        let plainCode: String
        switch CryptoManager.decrypt(code) {
        case .success(let plain), .legacyPlainText(let plain):
            plainCode = plain
        default:
            return nil
        }

        var components = URLComponents()
        components.scheme = "sesame"
        components.host = "import"

        var items: [URLQueryItem] = [
            URLQueryItem(name: "v", value: "1"),
            URLQueryItem(name: "label", value: label),
            URLQueryItem(name: "address", value: address),
            URLQueryItem(name: "code", value: plainCode)
        ]

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

        components.queryItems = items
        return components.url
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
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems else { return nil }

        func param(_ name: String) -> String? {
            items.first(where: { $0.name == name })?.value
        }

        let version = param("v") ?? "1"
        guard version == "1" else { return nil }

        guard let label = param("label"),
              let address = param("address"),
              let code = param("code"),
              !label.isEmpty, !address.isEmpty, !code.isEmpty else { return nil }

        return ParsedImport(
            label: label,
            address: address,
            code: code,
            radiusMeters: param("radius").flatMap { Double($0) },
            locationDetails: param("details"),
            comment: param("comment"),
            isSilenced: param("silenced") == "1"
        )
    }
}
