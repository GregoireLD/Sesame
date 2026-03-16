//
//  DecryptedAccessCode.swift
//  Sesame
//
//  Created by Greg on 2026-03-14.
//

import Foundation

/// Represents the decrypted view of an AccessCode entry.
/// This is a transient struct — never persisted, only used in the UI layer.
struct DecryptedAccessCode: Identifiable {
    let id: String
    let source: AccessCode

    let label: String
    let address: String

    // Decrypted sensitive fields
    let code: FieldValue
    let locationDetails: FieldValue
    let comment: FieldValue

    enum FieldValue {
        case available(String)      // Successfully decrypted or empty
        case keyUnavailable         // Key not in Keychain yet
        case futureVersion          // Written by newer app version
    }

    var isReadable: Bool {
        switch code {
        case .available: return true
        default: return false
        }
    }

    var isFutureVersion: Bool {
        switch code {
        case .futureVersion: return true
        default: return false
        }
    }
}
