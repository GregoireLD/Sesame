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
    var onDelete: (() -> Void)? = nil

    @State private var label: String = ""
    @State private var code: String = ""
    @State private var address: String = ""
    @State private var radiusMeters: Double = 100.0
    @State private var isSilenced: Bool = false
    @State private var latitude: Double? = nil
    @State private var longitude: Double? = nil
    @State private var locationDetails: String = ""
    @State private var comment: String = ""
    @State private var isPopulating: Bool = false
    @State private var showingDeleteConfirmation: Bool = false

    @State private var isGeocoding: Bool = false
    @State private var geocodingError: String? = nil
    @State private var geocodingSuccess: Bool = false
    @State private var showingCode: Bool = false
    @State private var keyUnavailable: Bool = false
    @State private var showingUnresolvedWarning: Bool = false
    @State private var showingClipboardError: Bool = false
    @State private var showingClipboardOverwriteWarning: Bool = false
    @State private var pendingClipboardImport: ParsedImport? = nil

    // Focus state for auto-resolve on focus loss
    @FocusState private var addressFocused: Bool

    private var isEditing: Bool { existingCode != nil }

    private var canSave: Bool {
        !label.isEmpty
    }

    // True if entry has no coordinates — drives the unresolved indicator
    private var isUnresolved: Bool {
        !geocodingSuccess && !address.isEmpty
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
                
                ToolbarItem(placement: .topBarTrailing) {
                    if importedValues == nil {
                        Button("Clipboard", systemImage: "doc.on.clipboard") {
                            importFromClipboard()
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") { attemptSave() }
                        .disabled(!canSave)
                }
            }
            .onAppear { populateIfEditing() }
            // Track unsaved changes on any field edit
            .onChange(of: address) { oldValue, newValue in
                // Only invalidate geocoding if the address actually changed
                // and we're not in the middle of a programmatic population
                guard !isPopulating, newValue != oldValue else { return }
                geocodingSuccess = false
                geocodingError = nil
                latitude = nil
                longitude = nil
            }
            // Auto-resolve address on focus loss
            .onChange(of: addressFocused) { _, focused in
                if !focused && !address.isEmpty && !geocodingSuccess && !isGeocoding {
                    geocodeAddress()
                }
            }
            // Key unavailable error
            .alert(
                String(localized: "error.key_unavailable.title"),
                isPresented: $keyUnavailable
            ) {
                Button(String(localized: "action.ok"), role: .cancel) { }
            } message: {
                Text("error.key_unavailable.message")
            }
            // Unresolved address warning
            .alert(
                String(localized: "address.warning.title"),
                isPresented: $showingUnresolvedWarning
            ) {
                // Replace the unresolved warning alert's Save anyway button
                Button(String(localized: "address.warning.save_anyway")) {
                    forceSave()
                }
                Button(String(localized: "action.cancel"), role: .cancel) { }
            } message: {
                Text("address.warning.message")
            }
            // Clipboard import error
            .alert(
                String(localized: "clipboard.error.title"),
                isPresented: $showingClipboardError
            ) {
                Button(String(localized: "action.ok"), role: .cancel) { }
            } message: {
                Text("clipboard.error.message")
            }
            // Deletion alert
            .alert(
                String(localized: "delete.confirm.title"),
                isPresented: $showingDeleteConfirmation
            ) {
                Button(String(localized: "action.delete"), role: .destructive) {
                    deleteEntry()
                }
                Button(String(localized: "action.cancel"), role: .cancel) { }
            } message: {
                Text("delete.confirm.message")
            }
            // Clipboard Overwrite Warning
            .alert(
                String(localized: "clipboard.overwrite.title"),
                isPresented: $showingClipboardOverwriteWarning
            ) {
                Button(String(localized: "clipboard.overwrite.confirm"), role: .destructive) {
                    if let parsed = pendingClipboardImport {
                        applyClipboardImport(parsed)
                        pendingClipboardImport = nil
                    }
                }
                Button(String(localized: "action.cancel"), role: .cancel) {
                    pendingClipboardImport = nil
                }
            } message: {
                Text("clipboard.overwrite.message")
            }
        }
    }

    // MARK: - Sections

    private var labelSection: some View {
        Section {
            TextField(String(localized: "label.placeholder"), text: $label)
                .textContentType(.oneTimeCode)
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
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .textContentType(.oneTimeCode)
                        .id("code-visible")
                } else {
                    SecureField(String(localized: "code.placeholder"), text: $code)
                        .textContentType(.oneTimeCode)
                        .id("code-hidden")
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
                .focused($addressFocused)
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
            if geocodingSuccess, let lat = latitude, let lon = longitude {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.5f, %.5f", lat, lon))
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
                showingDeleteConfirmation = true
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

    private func importFromClipboard() {
        guard let string = UIPasteboard.general.string,
              let url = URL(string: string),
              let parsed = ImportExport.parse(url: url) else {
            showingClipboardError = true
            return
        }

        // Check if the form already has meaningful content
        let formHasContent = !label.isEmpty || !code.isEmpty
            || !address.isEmpty || !locationDetails.isEmpty || !comment.isEmpty

        if formHasContent {
            pendingClipboardImport = parsed
            showingClipboardOverwriteWarning = true
        } else {
            applyClipboardImport(parsed)
        }
    }

    private func applyClipboardImport(_ parsed: ParsedImport) {
        isPopulating = true
        label = parsed.label
        address = parsed.address ?? ""
        code = parsed.code ?? ""
        locationDetails = parsed.locationDetails ?? ""
        comment = parsed.comment ?? ""
        isSilenced = parsed.isSilenced
        if let radius = parsed.radiusMeters {
            radiusMeters = radius
        }
        // Use embedded coordinates if present, otherwise geocode
        if let lat = parsed.latitude, let lon = parsed.longitude {
            latitude = lat
            longitude = lon
            geocodingSuccess = true
        } else {
            geocodeAddress()
        }
        isPopulating = false
    }

    private func populateIfEditing() {
        isPopulating = true
        defer { isPopulating = false }
        
        // Handle import pre-population
        if let imported = importedValues {
            label = imported.label
            address = imported.address ?? ""
            code = imported.code ?? ""
            locationDetails = imported.locationDetails ?? ""
            comment = imported.comment ?? ""
            isSilenced = imported.isSilenced
            if let radius = imported.radiusMeters {
                radiusMeters = radius
            }
            // Use embedded coordinates if present, otherwise geocode
            if let lat = imported.latitude, let lon = imported.longitude {
                latitude = lat
                longitude = lon
                geocodingSuccess = true
            } else {
                geocodeAddress()
            }
            
            return
        }

        // Handle edit pre-population
        guard let existing = existingCode else { return }
        label = existing.label ?? ""
        address = existing.address ?? ""
        if let lat = existing.latitude, let lon = existing.longitude {
            latitude = lat
            longitude = lon
            geocodingSuccess = true
        } else {
            latitude = nil
            longitude = nil
            geocodingSuccess = false
        }
        radiusMeters = existing.radiusMeters ?? 100.0
        isSilenced = existing.isSilenced ?? false

        // Only mark geocoding success if we have valid coordinates
        if let lat = existing.latitude, let lon = existing.longitude,
           lat != 0 || lon != 0 {
            geocodingSuccess = true
        }

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
        latitude = nil
        longitude = nil

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

    private func attemptSave() {
        if !address.isEmpty && !geocodingSuccess && !isGeocoding {
            isGeocoding = true
            geocodingError = nil
            latitude = nil
            longitude = nil

            Task {
                guard let request = MKGeocodingRequest(addressString: address) else {
                    await MainActor.run {
                        isGeocoding = false
                        geocodingError = String(localized: "address.error.empty")
                        showingUnresolvedWarning = true
                    }
                    return
                }
                do {
                    let mapItems = try await request.mapItems
                    guard let coordinate = mapItems.first?.location.coordinate else {
                        await MainActor.run {
                            isGeocoding = false
                            geocodingError = String(localized: "address.error.not_found")
                            showingUnresolvedWarning = true
                        }
                        return
                    }
                    await MainActor.run {
                        latitude = coordinate.latitude
                        longitude = coordinate.longitude
                        geocodingSuccess = true
                        isGeocoding = false
                        performSave()
                    }
                } catch {
                    await MainActor.run {
                        geocodingError = String(
                            localized: "address.error.generic \(error.localizedDescription)"
                        )
                        isGeocoding = false
                        showingUnresolvedWarning = true
                    }
                }
            }
            return
        }

        if !geocodingSuccess {
            showingUnresolvedWarning = true
            return
        }
        performSave()
    }

    private func forceSave() {
        performSave()
    }

    private func performSave() {
        // Encrypt code if present
        let encryptedCode: String?
        if !code.isEmpty {
            switch CryptoManager.encrypt(code) {
            case .success(let enc):
                encryptedCode = enc
            case .keyUnavailable:
                keyUnavailable = true
                return
            default:
                return
            }
        } else {
            encryptedCode = nil
        }

        // Encrypt location details if present
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

        // Encrypt comment if present
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
            existing.address = address.isEmpty ? nil : address
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
                address: address.isEmpty ? nil : address,
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
        onDelete?()
        dismiss()
    }
}
