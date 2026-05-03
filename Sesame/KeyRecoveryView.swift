//
//  KeyRecoveryView.swift
//  Sesame
//
//  Created by Greg on 2026-05-03.
//

import SwiftUI

struct KeyRecoveryView: View {

    let onReset: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingResetConfirmation: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(String(localized: "key.recovery.explanation.title"), systemImage: "lock.trianglebadge.exclamationmark.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                        Text("key.recovery.explanation.body")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("key.recovery.open_settings", systemImage: "gear")
                    }
                } footer: {
                    Text("key.recovery.settings_footer")
                }

                Section {
                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        Label("key.recovery.reset", systemImage: "trash.fill")
                    }
                } footer: {
                    Text("key.recovery.reset_footer")
                }
            }
            .navigationTitle(Text("key.recovery.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "action.ok")) { dismiss() }
                }
            }
            .alert(
                String(localized: "key.recovery.reset_confirm.title"),
                isPresented: $showingResetConfirmation
            ) {
                Button(String(localized: "key.recovery.reset_confirm.action"), role: .destructive) {
                    onReset()
                    dismiss()
                }
                Button(String(localized: "action.cancel"), role: .cancel) { }
            } message: {
                Text("key.recovery.reset_confirm.message")
            }
        }
    }
}
