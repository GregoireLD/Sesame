//
//  CryptoManager.swift
//  Sesame
//
//  Created by Greg on 2026-03-14.
//

import Foundation
import CryptoKit
import Security

enum EncryptionStatus {
    case success(String)
    case keyUnavailable
    case unknownVersion
    case legacyPlainText(String)
}

enum DecryptionStatus {
    case success(String)
    case keyUnavailable
    case unknownVersion
    case legacyPlainText(String)
}

struct CryptoManager {

    // MARK: - Constants

    private static let keyTag = "paris.com.duval.sesame.encryptionKey"
    nonisolated private static let currentVersion = "v1"
    nonisolated private static let separator = ":"

    // MARK: - Key Management

    /// Read-only key fetch. Returns nil if the key hasn't arrived yet (e.g. iCloud Keychain
    /// still syncing on a new device). Never creates a key — safe to call on the decrypt path.
    static func getKey() -> SymmetricKey? {
        return loadKey()
    }

    /// Retrieves the encryption key from iCloud Keychain.
    /// If no key exists yet, generates one and stores it.
    /// Only call this on the encrypt path (save), never on decrypt.
    static func getOrCreateKey() -> SymmetricKey? {
        if let existingKey = loadKey() {
            return existingKey
        }
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        if storeKey(keyData) {
            return newKey
        }
        return nil
    }

    private static func loadKey() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyTag,
            kSecAttrSynchronizable as String: kCFBooleanTrue!,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let keyData = result as? Data else { return nil }
        return SymmetricKey(data: keyData)
    }

    static func deleteKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyTag,
            kSecAttrSynchronizable as String: kCFBooleanTrue!
        ]
        SecItemDelete(query as CFDictionary)
    }

    private static func storeKey(_ keyData: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyTag,
            kSecAttrSynchronizable as String: kCFBooleanTrue!,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Encryption

    /// Encrypts a plain text string.
    /// Returns a versioned string in the format: v1:<nonce>:<ciphertext>
    static func encrypt(_ plainText: String) -> EncryptionStatus {
        guard let key = getOrCreateKey() else {
            return .keyUnavailable
        }
        guard let data = plainText.data(using: .utf8) else {
            return .keyUnavailable
        }
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            guard let combined = sealedBox.combined else {
                return .keyUnavailable
            }
            // Store nonce and ciphertext separately for forward compatibility
            let nonceBase64 = Data(sealedBox.nonce).base64EncodedString()
            let ciphertextBase64 = combined.base64EncodedString()
            let versioned = "\(currentVersion)\(separator)\(nonceBase64)\(separator)\(ciphertextBase64)"
            return .success(versioned)
        } catch {
            return .keyUnavailable
        }
    }

    // MARK: - Decryption

    /// Decrypts a versioned encrypted string.
    /// Handles legacy plain text, current v1 format, and unknown future versions.
    static func decrypt(_ stored: String) -> DecryptionStatus {
        // Check for version prefix
        if !stored.contains(separator) {
            // No prefix — legacy plain text from before encryption was added
            return .legacyPlainText(stored)
        }

        let parts = stored.split(separator: Character(separator), maxSplits: 2)
            .map(String.init)

        guard parts.count == 3 else {
            // Malformed — treat as legacy
            return .legacyPlainText(stored)
        }

        let version = parts[0]

        switch version {
        case "v1":
            return decryptV1(ciphertextBase64: parts[2])
        default:
            // Unknown version — written by a future app
            return .unknownVersion
        }
    }

    private static func decryptV1(ciphertextBase64: String) -> DecryptionStatus {
        guard let key = getKey() else {
            return .keyUnavailable
        }
        guard let combined = Data(base64Encoded: ciphertextBase64) else {
            return .keyUnavailable
        }
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: combined)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            guard let plainText = String(data: decryptedData, encoding: .utf8) else {
                return .keyUnavailable
            }
            return .success(plainText)
        } catch {
            return .keyUnavailable
        }
    }

    // MARK: - Helpers

    /// Returns true if a stored value is already encrypted in any known version
    nonisolated static func isEncrypted(_ value: String) -> Bool {
        return value.hasPrefix("v1\(separator)")
    }

    /// Returns true if a stored value was encrypted by an unknown future version
    nonisolated static func isFutureVersion(_ value: String) -> Bool {
        guard value.contains(separator) else { return false }
        let version = String(value.split(separator: Character(separator),
                                        maxSplits: 1)[0])
        return version != "v1" && version.hasPrefix("v")
    }
}
