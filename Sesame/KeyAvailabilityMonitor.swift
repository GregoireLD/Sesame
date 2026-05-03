//
//  KeyAvailabilityMonitor.swift
//  Sesame
//
//  Created by Greg on 2026-05-03.
//

import Foundation
import SwiftData

@Observable
final class KeyAvailabilityMonitor {

    enum State {
        case available
        case unavailableNoData   // no key, but nothing encrypted yet — safe, just wait
        case unavailableWithData // no key, encrypted entries exist — user needs to act
    }

    private(set) var state: State = .available

    func check(context: ModelContext) {
        guard CryptoManager.getKey() == nil else {
            state = .available
            return
        }
        let descriptor = FetchDescriptor<AccessCode>()
        guard let entries = try? context.fetch(descriptor) else {
            state = .unavailableNoData
            return
        }
        let hasEncrypted = entries.contains {
            ($0.code.map(CryptoManager.isEncrypted) ?? false) ||
            ($0.locationDetails.map(CryptoManager.isEncrypted) ?? false) ||
            ($0.comment.map(CryptoManager.isEncrypted) ?? false) ||
            ($0.encryptedAddress.map(CryptoManager.isEncrypted) ?? false) ||
            ($0.encryptedLatitude.map(CryptoManager.isEncrypted) ?? false)
        }
        state = hasEncrypted ? .unavailableWithData : .unavailableNoData
    }

    /// Forces the unavailable-with-data state for UI testing. Hidden feature only.
    func simulateBrokenKey() {
        state = .unavailableWithData
    }

    /// Deletes all entries and the encryption key across all devices.
    /// This is irreversible.
    func resetAllData(context: ModelContext) {
        let descriptor = FetchDescriptor<AccessCode>()
        guard let entries = try? context.fetch(descriptor) else { return }
        for entry in entries {
            context.delete(entry)
        }
        try? context.save()
        CryptoManager.deleteKey()
        state = .unavailableNoData
    }
}
