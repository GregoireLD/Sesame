//
//  AddEditView.swift
//  Sesame
//
//  Created by Greg on 2026-03-12.
//

import SwiftUI
import SwiftData
import MapKit

struct AddEditView: View {

    @Environment(LocationManager.self) private var locationManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var existingCode: AccessCode? = nil
    var importedValues: ParsedImport? = nil

    @State private var label: String = ""
    @State private var code: String = ""
    @State private var address: String = ""
    @State private var radiusMeters: Double = 100.0
    @State private var isSilenced: Bool = false
    @State private var latitude: Double = 0.0
    @State private var longitude: Double = 0.0
    @State private var locationDetails: String = ""
    @State private var comment: String = ""

    @State private var isGeocoding: Bool = false
    @State private var geocodingError: String? = nil
    @State private var geocodingSuccess: Bool = false
    @State private var showingCode: Bool = false
    @State private var keyUnavailable: Bool = false
    @State private var showingQRShare: Bool = false

    private var isEditing: Bool { existingCode != nil }
    private var canSave: Bool {
        !label.isEmpty && !code.isEmpty && geocodingSuccess
    }

    var body: some View {
        NavigationStack {
            Form {
                labelSection
                codeSection
                addressSection
                radiusSection
                locationDetailsSection
                commentSection
                if isEditing {
                    deleteSection
                }
            }
            .navigationTitle(
                isEditing ? Text("edit.title") :
                importedValues != nil ? Text("import.title") :
                Text("add.title")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                }
                if isEditing {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("QRCode", systemImage: "qrcode") { showingQRShare = true }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") { save() }
                    .disabled(!canSave)
                }
            }
            .onAppear { populateIfEditing() }
            .sheet(isPresented: $showingQRShare) {
                if let existing = existingCode {
                    QRShareView(accessCode: existing)
                }
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

    // MARK: - Sections

    private var labelSection: some View {
        Section {
            TextField(String(localized: "label.placeholder"), text: $label)
        } header: {
            Text("label.header")
        } footer: {
            Text("label.footer")
        }
    }

    private var codeSection: some View {
        Section {
            HStack {
                if showingCode {
                    TextField(String(localized: "code.placeholder"), text: $code)
                } else {
                    SecureField(String(localized: "code.placeholder"), text: $code)
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
        } header: {
            Text("code.header")
        } footer: {
            Text("code.footer")
        }
    }

    private var addressSection: some View {
        Section {
            TextField(String(localized: "address.placeholder"), text: $address)
                .autocorrectionDisabled()
            Button {
                geocodeAddress()
            } label: {
                HStack {
                    if isGeocoding {
                        ProgressView()
                            .padding(.trailing, 4)
                        Text("address.looking_up")
                    } else if geocodingSuccess {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("address.found")
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "magnifyingglass")
                        Text("address.look_up")
                    }
                }
            }
            .disabled(address.isEmpty || isGeocoding)
            if let error = geocodingError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.footnote)
            }
            if geocodingSuccess {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.5f, %.5f", latitude, longitude))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("address.header")
        } footer: {
            Text("address.footer")
        }
    }

    private var radiusSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                        Text(formattedRadius)
                            .fontWeight(.semibold)
                        HStack(spacing: 12) {
                            Slider(value: $radiusMeters, in: 50...500, step: 10)
                            Button {
                                isSilenced.toggle()
                            } label: {
                                Image(systemName: isSilenced ? "bell.slash.fill" : "bell.fill")
                                    .foregroundStyle(isSilenced ? Color.secondary : Color.orange)
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
        } header: {
            Text("radius.header")
        } footer: {
            Text("radius.footer \(Measurement(value: 100, unit: UnitLength.meters), format: .measurement(width: .wide, usage: .road))")
        }
    }

    private var locationDetailsSection: some View {
        Section {
            TextField(
                String(localized: "location_details.placeholder"),
                text: $locationDetails,
                axis: .vertical
            )
            .lineLimit(3...6)
        } header: {
            Text("location_details.header")
        } footer: {
            Text("location_details.footer")
        }
    }

    private var commentSection: some View {
        Section {
            TextField(
                String(localized: "comment.placeholder"),
                text: $comment,
                axis: .vertical
            )
            .lineLimit(3...6)
        } header: {
            Text("comment.header")
        } footer: {
            Text("comment.footer")
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                deleteEntry()
            } label: {
                HStack {
                    Spacer()
                    Text("action.delete")
                    Spacer()
                }
            }
        }
    }
    
    private var formattedRadius: String {
        let measurement = Measurement<UnitLength>(value: radiusMeters, unit: UnitLength.meters)
        let distanceStyle = Measurement<UnitLength>.FormatStyle(width: .abbreviated, usage: .road)
        return distanceStyle.format(measurement)
    }

    // MARK: - Logic

    private func populateIfEditing() {
        // Handle import pre-population
        if let imported = importedValues {
            label = imported.label
            address = imported.address
            code = imported.code
            locationDetails = imported.locationDetails ?? ""
            comment = imported.comment ?? ""
            isSilenced = imported.isSilenced
            if let radius = imported.radiusMeters {
                radiusMeters = radius
            }
            geocodeAddress()
            return
        }

        // Handle edit pre-population
        guard let existing = existingCode else { return }
        label = existing.label ?? ""
        address = existing.address ?? ""
        latitude = existing.latitude ?? 0.0
        longitude = existing.longitude ?? 0.0
        radiusMeters = existing.radiusMeters ?? 100.0
        isSilenced = existing.isSilenced ?? false
        geocodingSuccess = true

        if let storedCode = existing.code {
            switch CryptoManager.decrypt(storedCode) {
            case .success(let plain), .legacyPlainText(let plain):
                code = plain
            case .keyUnavailable:
                keyUnavailable = true
            case .unknownVersion:
                keyUnavailable = true
            }
        }

        if let storedDetails = existing.locationDetails {
            switch CryptoManager.decrypt(storedDetails) {
            case .success(let plain), .legacyPlainText(let plain):
                locationDetails = plain
            default:
                break
            }
        }

        if let storedComment = existing.comment {
            switch CryptoManager.decrypt(storedComment) {
            case .success(let plain), .legacyPlainText(let plain):
                comment = plain
            default:
                break
            }
        }
    }

    private func geocodeAddress() {
        geocodingSuccess = false
        isGeocoding = true
        geocodingError = nil

        Task {
            guard let request = MKGeocodingRequest(addressString: address) else {
                isGeocoding = false
                geocodingError = String(localized: "address.error.empty")
                return
            }
            do {
                let mapItems = try await request.mapItems
                guard let coordinate = mapItems.first?.location.coordinate else {
                    isGeocoding = false
                    geocodingError = String(localized: "address.error.not_found")
                    return
                }
                latitude = coordinate.latitude
                longitude = coordinate.longitude
                geocodingSuccess = true
            } catch {
                geocodingError = String(
                    localized: "address.error.generic \(error.localizedDescription)"
                )
            }
            isGeocoding = false
        }
    }

    private func save() {
        let encryptedCode: String
        switch CryptoManager.encrypt(code) {
        case .success(let enc):
            encryptedCode = enc
        case .keyUnavailable:
            keyUnavailable = true
            return
        default:
            return
        }

        let encryptedLocationDetails: String?
        if !locationDetails.isEmpty {
            if case .success(let enc) = CryptoManager.encrypt(locationDetails) {
                encryptedLocationDetails = enc
            } else {
                keyUnavailable = true
                return
            }
        } else {
            encryptedLocationDetails = nil
        }

        let encryptedComment: String?
        if !comment.isEmpty {
            if case .success(let enc) = CryptoManager.encrypt(comment) {
                encryptedComment = enc
            } else {
                keyUnavailable = true
                return
            }
        } else {
            encryptedComment = nil
        }

        if let existing = existingCode {
            locationManager.stopMonitoring(accessCode: existing)
            existing.label = label
            existing.code = encryptedCode
            existing.address = address
            existing.latitude = latitude
            existing.longitude = longitude
            existing.radiusMeters = radiusMeters
            existing.isSilenced = isSilenced
            existing.locationDetails = encryptedLocationDetails
            existing.comment = encryptedComment
            existing.schemaVersion = 3
            locationManager.startMonitoring(accessCode: existing)
        } else {
            let newCode = AccessCode(
                label: label,
                code: encryptedCode,
                address: address,
                latitude: latitude,
                longitude: longitude,
                radiusMeters: radiusMeters,
                isSilenced: isSilenced,
                locationDetails: encryptedLocationDetails,
                comment: encryptedComment
            )
            modelContext.insert(newCode)
            locationManager.startMonitoring(accessCode: newCode)
        }
        dismiss()
    }

    private func deleteEntry() {
        guard let existing = existingCode else { return }
        locationManager.stopMonitoring(accessCode: existing)
        modelContext.delete(existing)
        dismiss()
    }
}
