//
//  Item.swift
//  Sesame
//
//  Created by Greg on 2026-03-12.
//

import Foundation
import SwiftData

@Model
final class AccessCode {
    var id: UUID?
    var label: String?
    var code: String?
    // Legacy plaintext fields — kept for migration only, nil after MigrationManager runs
    var address: String?
    var latitude: Double?
    var longitude: Double?
    // Encrypted location fields (replaces the three above)
    var encryptedAddress: String?
    var encryptedLatitude: String?
    var encryptedLongitude: String?
    var radiusMeters: Double?
    var isSilenced: Bool?
    var locationDetails: String?
    var comment: String?
    var schemaVersion: Int?

    init(
        label: String,
        code: String? = nil,
        encryptedAddress: String? = nil,
        encryptedLatitude: String? = nil,
        encryptedLongitude: String? = nil,
        radiusMeters: Double = 100.0,
        isSilenced: Bool = false,
        locationDetails: String? = nil,
        comment: String? = nil
    ) {
        self.id = UUID()
        self.label = label
        self.code = code
        self.encryptedAddress = encryptedAddress
        self.encryptedLatitude = encryptedLatitude
        self.encryptedLongitude = encryptedLongitude
        self.radiusMeters = radiusMeters
        self.isSilenced = isSilenced
        self.locationDetails = locationDetails
        self.comment = comment
        self.schemaVersion = 3
        // Legacy fields always nil for new entries
        self.address = nil
        self.latitude = nil
        self.longitude = nil
    }

    // MARK: - Decrypted accessors

    var decryptedAddress: String? {
        guard let enc = encryptedAddress else { return nil }
        switch CryptoManager.decrypt(enc) {
        case .success(let plain), .legacyPlainText(let plain):
            return plain.isEmpty ? nil : plain
        default:
            return nil
        }
    }

    var decryptedLatitude: Double? {
        guard let enc = encryptedLatitude else { return nil }
        switch CryptoManager.decrypt(enc) {
        case .success(let plain), .legacyPlainText(let plain):
            return Double(plain)
        default:
            return nil
        }
    }

    var decryptedLongitude: Double? {
        guard let enc = encryptedLongitude else { return nil }
        switch CryptoManager.decrypt(enc) {
        case .success(let plain), .legacyPlainText(let plain):
            return Double(plain)
        default:
            return nil
        }
    }
}
