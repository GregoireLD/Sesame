//
//  MigrationManager.swift
//  Sesame
//
//  Created by Greg on 2026-03-14.
//

import Foundation
import SwiftData

struct MigrationManager {

    /// Call this once on app launch.
    /// Finds all entries with unencrypted sensitive fields and encrypts them.
    static func migrateIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<AccessCode>()
        guard let entries = try? context.fetch(descriptor) else { return }

        var didChange = false

        for entry in entries {
            // Migrate code field
            if let code = entry.code, !code.isEmpty,
               !CryptoManager.isEncrypted(code),
               !CryptoManager.isFutureVersion(code) {
                if case .success(let encrypted) = CryptoManager.encrypt(code) {
                    entry.code = encrypted
                    didChange = true
                }
            }

            // Migrate locationDetails field
            if let locationDetails = entry.locationDetails,
               !locationDetails.isEmpty,
               !CryptoManager.isEncrypted(locationDetails),
               !CryptoManager.isFutureVersion(locationDetails) {
                if case .success(let encrypted) = CryptoManager.encrypt(locationDetails) {
                    entry.locationDetails = encrypted
                    didChange = true
                }
            }

            // Migrate comment field
            if let comment = entry.comment,
               !comment.isEmpty,
               !CryptoManager.isEncrypted(comment),
               !CryptoManager.isFutureVersion(comment) {
                if case .success(let encrypted) = CryptoManager.encrypt(comment) {
                    entry.comment = encrypted
                    didChange = true
                }
            }

            // Migrate address
            if let addr = entry.address, !addr.isEmpty,
               entry.encryptedAddress == nil {
                if case .success(let encrypted) = CryptoManager.encrypt(addr) {
                    entry.encryptedAddress = encrypted
                    entry.address = nil
                    didChange = true
                }
            }

            // Migrate latitude
            if let lat = entry.latitude,
               entry.encryptedLatitude == nil {
                if case .success(let encrypted) = CryptoManager.encrypt(String(lat)) {
                    entry.encryptedLatitude = encrypted
                    entry.latitude = nil
                    didChange = true
                }
            }

            // Migrate longitude
            if let lon = entry.longitude,
               entry.encryptedLongitude == nil {
                if case .success(let encrypted) = CryptoManager.encrypt(String(lon)) {
                    entry.encryptedLongitude = encrypted
                    entry.longitude = nil
                    didChange = true
                }
            }
        }

        if didChange {
            try? context.save()
        }
    }
}
