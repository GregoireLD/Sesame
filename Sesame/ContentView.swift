//
//  ContentView.swift
//  Sesame
//
//  Created by Greg on 2026-03-12.
//

import SwiftUI
import SwiftData
import CoreLocation
import CoreData

enum SortOrder: String {
    case alphabetical
    case byDistance
}

struct ContentView: View {

    @Environment(LocationManager.self) private var locationManager
    @Environment(\.modelContext) private var modelContext
    @Query private var accessCodes: [AccessCode]

    @State private var lastRefresh: Date = .now
    @State private var showingAddSheet = false
    @State private var selectedCode: AccessCode? = nil
    @Binding var selectedEntryID: String?
    
    @State private var showingAbout: Bool = false
    @State private var searchText: String = ""
    
    @State private var notificationsAuthorized: Bool = true
    
    init(selectedEntryID: Binding<String?> = .constant(nil)) {
        self._selectedEntryID = selectedEntryID
    }

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("locationBannerDismissed") private var locationBannerDismissed = false
    @AppStorage("notificationBannerDismissed") private var notificationBannerDismissed = false
    
    @AppStorage("sortOrder") private var sortOrderRaw: String = SortOrder.byDistance.rawValue

    private var sortOrder: SortOrder {
        SortOrder(rawValue: sortOrderRaw) ?? .alphabetical
    }
    
    private var canSortByDistance: Bool {
        locationManager.authorizationStatus == .authorizedAlways
            || locationManager.authorizationStatus == .authorizedWhenInUse
    }

    private var effectiveSortByDistance: Bool {
        sortOrder == .byDistance && canSortByDistance
    }

    private var sortedCodes: [AccessCode] {
        if effectiveSortByDistance,
           let location = locationManager.currentLocation {
            return accessCodes.sorted {
                let loc0 = CLLocation(latitude: $0.latitude ?? 0, longitude: $0.longitude ?? 0)
                let loc1 = CLLocation(latitude: $1.latitude ?? 0, longitude: $1.longitude ?? 0)
                return location.distance(from: loc0) < location.distance(from: loc1)
            }
        }
        return accessCodes.sorted {
            ($0.label ?? "") < ($1.label ?? "")
        }
    }
    
    private var filteredCodes: [AccessCode] {
        guard !searchText.isEmpty else { return sortedCodes }
        return sortedCodes.filter { code in
            (code.label ?? "").localizedCaseInsensitiveContains(searchText) ||
            (code.address ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if accessCodes.isEmpty {
                    emptyState
                } else if filteredCodes.isEmpty {
                    searchEmptyState
                } else {
                    list
                }
            }
            .navigationTitle(Text("app.name"))
            .searchable(text: $searchText, prompt: Text("search.prompt"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    sortButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddEditView()
                    .environment(locationManager)
            }
            .sheet(item: $selectedCode) { code in
                AddEditView(existingCode: code)
                    .environment(locationManager)
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
                        .environment(locationManager)
            }
            .overlay(alignment: .bottom) {
                authorizationBanner
            }
            .onReceive(NotificationCenter.default.publisher(
                for: NSPersistentCloudKitContainer.eventChangedNotification
            )) { _ in
                lastRefresh = .now
            }
            .onReceive(NotificationCenter.default.publisher(
                for: UIApplication.didBecomeActiveNotification
            )) { _ in
                checkNotificationStatus()
            }
            .onChange(of: selectedEntryID) { _, newID in
                guard let newID else { return }
                if let match = accessCodes.first(where: { $0.id?.uuidString == newID }) {
                    selectedCode = match
                }
                selectedEntryID = nil
            }
            .onChange(of: accessCodes) { _, newCodes in
                locationManager.restartAllMonitoring(accessCodes: newCodes)
            }
            .fullScreenCover(isPresented: .init(
                get: { !hasCompletedOnboarding },
                set: { _ in }
            )) {
                OnboardingView()
                    .environment(locationManager)
            }
        }
    }

    // MARK: - Subviews

    private var sortButton: some View {
        Menu {
            Button {
                showingAbout = true
            } label: {
                Label(
                    String(localized: "about.title"),
                    systemImage: "info.circle"
                )
            }
            Divider()
            Button {
                sortOrderRaw = SortOrder.alphabetical.rawValue
            } label: {
                Label(
                    String(localized: "sort.alphabetical"),
                    systemImage: sortOrder == .alphabetical
                        ? "checkmark"
                        : "textformat.abc"
                )
            }
            Button {
                sortOrderRaw = SortOrder.byDistance.rawValue
            } label: {
                Label(
                    String(localized: "sort.by_distance"),
                    systemImage: sortOrder == .byDistance
                        ? "checkmark"
                        : "location"
                )
            }
        } label: {
            // Show slash icon when preference is distance but location unavailable
            if sortOrder == .byDistance && !canSortByDistance {
                Image(systemName: "location.slash.fill")
                    .foregroundStyle(.secondary)
            } else if effectiveSortByDistance {
                Image(systemName: "location.fill")
            } else {
                Image(systemName: "textformat.abc")
            }
        }
    }

    private var list: some View {
        List {
            Section {
                ForEach(filteredCodes) { code in
                    row(for: code)
                }
                .onDelete(perform: delete)
            }
        }
        .refreshable {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }

    private func row(for code: AccessCode) -> some View {
        Button {
            selectedCode = code
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(code.label ?? "")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(code.address ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack {
                    if isFutureVersion(code) {
                        Image(systemName: "lock.trianglebadge.exclamationmark.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("entry.requires_newer_version")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                        Text(maskedCode(for: code))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        if code.isSilenced == true {
                                    Image(systemName: "bell.slash.fill")
                                        .foregroundStyle(.tertiary)
                                        .font(.caption)
                                }
                    }
                    if effectiveSortByDistance,
                       let location = locationManager.currentLocation,
                       let lat = code.latitude,
                       let lon = code.longitude {
                        Spacer()
                        let distance = location.distance(from: CLLocation(
                            latitude: lat,
                            longitude: lon
                        ))
                        Text(distanceString(distance))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.vertical, 4)
            .opacity(isFutureVersion(code) ? 0.6 : 1.0)
        }
        .disabled(isFutureVersion(code))
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if !isFutureVersion(code) {
                Button {
                    code.isSilenced = !(code.isSilenced ?? false)
                } label: {
                    Label(
                        code.isSilenced == true
                            ? String(localized: "entry.unmute")
                            : String(localized: "entry.mute"),
                        systemImage: code.isSilenced == true
                            ? "bell.fill"
                            : "bell.slash.fill"
                    )
                }
                .tint(code.isSilenced == true ? .orange : .secondary)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "key.fill")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
            Text("empty.title")
                .font(.title2)
                .fontWeight(.semibold)
            Text("empty.subtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                showingAddSheet = true
            } label: {
                Text("empty.add_button")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var searchEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
            Text("search.empty.title")
                .font(.title2)
                .fontWeight(.semibold)
            Text("search.empty.subtitle \(searchText)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    @ViewBuilder
    private var authorizationBanner: some View {
        VStack(spacing: 12) {
            if locationManager.authorizationStatus != .authorizedAlways
                && !locationBannerDismissed {
                bannerView(
                    icon: "location.slash.fill",
                    message: String(localized: "permission.location.banner"),
                    onSettings: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    },
                    onDismiss: { locationBannerDismissed = true }
                )
            }
            if !notificationsAuthorized && !notificationBannerDismissed {
                bannerView(
                    icon: "bell.slash.fill",
                    message: String(localized: "permission.notification.banner"),
                    onSettings: {
                        UNUserNotificationCenter.current().getNotificationSettings { settings in
                            DispatchQueue.main.async {
                                switch settings.authorizationStatus {
                                case .notDetermined:
                                    // Never asked — show the native dialog, no need for Settings
                                    NotificationManager.shared.requestAuthorization()
                                case .denied:
                                    // Previously denied — must go to Settings
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                default:
                                    // authorized, provisional, ephemeral — shouldn't be here
                                    // but open Settings anyway as a safe fallback
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            }
                        }
                    },
                    onDismiss: { notificationBannerDismissed = true }
                )
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .onAppear { checkNotificationStatus() }
    }

    private func bannerView(
        icon: String,
        message: String,
        onSettings: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 8) {
            Label(message, systemImage: icon)
                .font(.footnote)
                .multilineTextAlignment(.center)
            HStack(spacing: 12) {
                Button(String(localized: "permission.open_settings")) {
                    onSettings()
                }
                .font(.footnote)
                .buttonStyle(.bordered)
                Button(String(localized: "action.dismiss")) {
                    onDismiss()
                }
                .font(.footnote)
                .buttonStyle(.bordered)
                .tint(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func distanceString(_ meters: CLLocationDistance) -> String {
        let measurement = Measurement<UnitLength>(value: meters, unit: UnitLength.meters)
        let distanceStyle = Measurement<UnitLength>.FormatStyle(width: .abbreviated, usage: .road)
        return distanceStyle.format(measurement)
    }

    private func isFutureVersion(_ code: AccessCode) -> Bool {
        guard let storedCode = code.code else { return false }
        return CryptoManager.isFutureVersion(storedCode)
    }

    private func maskedCode(for code: AccessCode) -> String {
        guard let storedCode = code.code else { return "" }
        switch CryptoManager.decrypt(storedCode) {
        case .success(let plain), .legacyPlainText(let plain):
            return String(repeating: "•", count: plain.count)
        case .keyUnavailable:
            return "••••"
        case .unknownVersion:
            return "?"
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Actions

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let code = filteredCodes[index]
            locationManager.stopMonitoring(accessCode: code)
            modelContext.delete(code)
        }
    }
}
