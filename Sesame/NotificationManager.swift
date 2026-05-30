//
//  NotificationManager.swift
//  Sesame
//
//  Created by Greg on 2026-03-12.
//

import Foundation
import UserNotifications
import SwiftData

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()
    var modelContainer: ModelContainer?

    private override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Authorization

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                #if DEBUG
                print("Notification authorization error: \(error.localizedDescription)")
                #endif
            }
        }
    }

    // MARK: - Sending Notifications

    func sendNotification(forRegionIdentifier identifier: String) {
        guard let container = modelContainer else { return }

        Task {
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<AccessCode>()
            guard let accessCodes = try? context.fetch(descriptor),
                  let match = accessCodes.first(where: { $0.id?.uuidString == identifier }),
                  let label = match.label
            else { return }

            // Respect the per-entry silence setting
            if match.isSilenced == true { return }

            var bodyLines: [String] = []

            if let code = match.code {
                let displayCode: String
                switch CryptoManager.decrypt(code) {
                case .success(let plain), .legacyPlainText(let plain):
                    displayCode = plain
                case .keyUnavailable:
                    displayCode = String(localized: "notification.code.key_unavailable")
                case .unknownVersion:
                    displayCode = String(localized: "notification.code.unknown_version")
                }
                bodyLines.append(String(localized: "notification.code.body \(displayCode)"))
            }

            if let locationDetails = match.locationDetails, !locationDetails.isEmpty {
                switch CryptoManager.decrypt(locationDetails) {
                case .success(let plain), .legacyPlainText(let plain):
                    if !plain.isEmpty { bodyLines.append(plain) }
                default:
                    break
                }
            }

            // Nothing to show — skip notification entirely
            guard !bodyLines.isEmpty else { return }

            let content = UNMutableNotificationContent()
            content.title = label
            content.body = bodyLines.joined(separator: "\n")
            content.sound = .default
            content.userInfo = ["entryID": identifier]
            content.categoryIdentifier = "ACCESS_CODE"

            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: nil
            )

            try? await center.add(request)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        if let entryID = userInfo["entryID"] as? String {
            await MainActor.run {
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenEntry"),
                    object: nil,
                    userInfo: ["entryID": entryID]
                )
            }
        }
    }
}
