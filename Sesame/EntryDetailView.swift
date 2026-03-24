//
//  EntryDetailView.swift
//  Sesame
//
//  Created by Greg on 2026-03-22.
//

import SwiftUI
import CoreLocation
import MapKit

struct EntryDetailView: View {

    @Environment(LocationManager.self) private var locationManager
    @Environment(\.dismiss) private var dismiss

    let accessCode: AccessCode

    @State private var showingCode: Bool = false
    @State private var showingEdit: Bool = false
    @State private var showingQRShare: Bool = false
    @State private var keyUnavailable: Bool = false
    @State private var shouldDismiss: Bool = false

    private var plainCode: String? {
        guard let stored = accessCode.code else { return nil }
        switch CryptoManager.decrypt(stored) {
        case .success(let plain), .legacyPlainText(let plain):
            return plain
        default:
            return nil
        }
    }

    private var plainLocationDetails: String? {
        guard let stored = accessCode.locationDetails else { return nil }
        switch CryptoManager.decrypt(stored) {
        case .success(let plain), .legacyPlainText(let plain):
            return plain.isEmpty ? nil : plain
        default:
            return nil
        }
    }

    private var plainComment: String? {
        guard let stored = accessCode.comment else { return nil }
        switch CryptoManager.decrypt(stored) {
        case .success(let plain), .legacyPlainText(let plain):
            return plain.isEmpty ? nil : plain
        default:
            return nil
        }
    }

    private var isFutureVersion: Bool {
        guard let stored = accessCode.code else { return false }
        return CryptoManager.isFutureVersion(stored)
    }

    private var isUnresolved: Bool {
        accessCode.latitude == nil && accessCode.longitude == nil
    }

    private var formattedRadius: String {
        let meters = accessCode.radiusMeters ?? 100.0
        let measurement = Measurement<UnitLength>(value: meters, unit: .meters)
        return Measurement<UnitLength>.FormatStyle(
            width: .abbreviated, usage: .road
        ).format(measurement)
    }

    var body: some View {
        NavigationStack {
            List {
                // ── Label ──────────────────────────────────────
                Section {
                    Text(accessCode.label ?? "")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .padding(.vertical, 4)
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = accessCode.label
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            } label: {
                                Label("action.copy", systemImage: "doc.on.doc")
                            }
                        }
                }

                // ── Code ───────────────────────────────────────
                Section {
                    if isFutureVersion {
                        Label {
                            Text("entry.requires_newer_version")
                                .foregroundStyle(.orange)
                        } icon: {
                            Image(systemName: "lock.trianglebadge.exclamationmark.fill")
                                .foregroundStyle(.orange)
                        }
                    } else if let plain = plainCode {
                        HStack {
                            Text(showingCode ? plain : String(repeating: "•", count: plain.count))
                                .font(.title3)
                                .fontWeight(.medium)
                                .monospaced()
                                .foregroundStyle(.primary)
                                .animation(.none, value: showingCode)
                                .contextMenu {
                                    if showingCode {
                                        Button {
                                            UIPasteboard.general.string = plain
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        } label: {
                                            Label("action.copy", systemImage: "doc.on.doc")
                                        }
                                    }
                                }
                            Spacer()
                            Button {
                                showingCode.toggle()
                            } label: {
                                Image(systemName: showingCode ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    } else {
                        Text("detail.no_code")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("code.header")
                }

                // ── Address ────────────────────────────────────
                Section {
                    if let address = accessCode.address, !address.isEmpty {
                        Button {
                            openInMaps()
                        } label: {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: isUnresolved
                                      ? "location.slash.fill"
                                      : "mappin.circle.fill")
                                    .foregroundStyle(isUnresolved ? Color.orange : Color.green)
                                    .padding(.top, 2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(address)
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.leading)
                                    if isUnresolved {
                                        Text("address.warning.message")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                }
                                Spacer()
                                if !isUnresolved {
                                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                        .foregroundStyle(Color.green)
                                        .font(.title3)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                        .disabled(isUnresolved)
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = address
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            } label: {
                                Label("action.copy", systemImage: "doc.on.doc")
                            }
                            if !isUnresolved {
                                Button {
                                    openInMaps()
                                } label: {
                                    Label("action.maps", systemImage: "map.fill")
                                }
                            }
                        }
                    }
                } header: {
                    Text("address.header")
                }

                // ── Radius & Silence ───────────────────────────
                Section {
                    HStack {
                        Image(systemName: "circle.dashed")
                            .foregroundStyle(.secondary)
                        Text(formattedRadius)
                        Spacer()
                        Image(systemName: accessCode.isSilenced == true
                              ? "bell.slash.fill"
                              : "bell.fill")
                            .foregroundStyle(accessCode.isSilenced == true
                                             ? Color.secondary
                                             : Color.orange)
                        Text(accessCode.isSilenced == true
                             ? String(localized: "detail.silenced")
                             : String(localized: "detail.active"))
                            .foregroundStyle(accessCode.isSilenced == true
                                             ? .secondary
                                             : .primary)
                    }
                } header: {
                    Text("radius.header")
                }

                // ── Location details ───────────────────────────
                if let details = plainLocationDetails {
                    Section {
                        Text(details)
                            .foregroundStyle(.primary)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = details
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                } label: {
                                    Label("action.copy", systemImage: "doc.on.doc")
                                }
                            }
                    } header: {
                        Text("location_details.header")
                    }
                }

                // ── Comment ────────────────────────────────────
                if let comment = plainComment {
                    Section {
                        Text(comment)
                            .foregroundStyle(.primary)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = comment
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                } label: {
                                    Label("action.copy", systemImage: "doc.on.doc")
                                }
                            }
                    } header: {
                        Text("comment.header")
                    }
                }
            }
            .navigationTitle(Text("detail.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingQRShare = true
                    } label: {
                        Image(systemName: "qrcode")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        showingEdit = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
            }
            .sheet(isPresented: $showingEdit, onDismiss: {
                if shouldDismiss { dismiss() }
            }) {
                AddEditView(existingCode: accessCode, onDelete: {
                    shouldDismiss = true
                })
                .environment(locationManager)
            }
            .sheet(isPresented: $showingQRShare) {
                QRShareView(accessCode: accessCode)
            }
            .alert(
                String(localized: "error.key_unavailable.title"),
                isPresented: $keyUnavailable
            ) {
                Button(String(localized: "action.ok"), role: .cancel) { }
            } message: {
                Text("error.key_unavailable.message")
            }
        }
    }

    private func openInMaps() {
        guard let lat = accessCode.latitude,
              let lon = accessCode.longitude,
              let label = accessCode.label else { return }
        let location = CLLocation(latitude: lat, longitude: lon)
        let mapItem = MKMapItem(location: location, address: nil)
        mapItem.name = label
        mapItem.openInMaps()
    }
}
