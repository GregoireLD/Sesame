//
//  SesameApp.swift
//  Sesame
//
//  Created by Greg on 2026-03-12.
//

import SwiftUI
import SwiftData

@main
struct SesameApp: App {
    let locationManager = LocationManager()
    let notificationManager = NotificationManager.shared
    let container: ModelContainer
    
    // This holds the ID of the entry to open when a notification is tapped
    @State private var selectedEntryID: String? = nil
    
    @State private var importURL: URL? = nil

    init() {
        let schema = Schema([AccessCode.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch let error as NSError {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)\nDomain: \(error.domain)\nCode: \(error.code)\nUser info: \(error.userInfo)")
        }

        notificationManager.modelContainer = container
        let context = ModelContext(container)

        // Migrate any plain text fields to encrypted format
        MigrationManager.migrateIfNeeded(context: context)

        let descriptor = FetchDescriptor<AccessCode>()
        if let accessCodes = try? context.fetch(descriptor) {
            locationManager.restartAllMonitoring(accessCodes: accessCodes)
        }
    }

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(selectedEntryID: $selectedEntryID)
                .environment(locationManager)
                .onOpenURL { url in
                    if url.scheme == "sesame", url.host == "import" {
                        importURL = url
                    } else if url.scheme == "https",
                              url.host == "duval.paris",
                              url.path == "/sesame/share" {
                        importURL = url
                    }
                }
                .sheet(item: $importURL) { url in
                    if let parsed = ImportExport.parse(url: url) {
                        AddEditView(importedValues: parsed)
                            .environment(locationManager)
                    } else {
                        // Unknown version or malformed URL
                        UnknownImportView(url: url)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(
                    for: NSNotification.Name("OpenEntry")
                )) { notification in
                    if let id = notification.userInfo?["entryID"] as? String {
                        selectedEntryID = id
                    }
                }
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                // App came to foreground — start precise location
                // and recalculate active set
                locationManager.startUpdatingLocation()
                locationManager.recalculateActiveSet()
            case .background:
                // App went to background — switch to battery-friendly
                // significant location changes only
                locationManager.stopUpdatingLocation()
                locationManager.startMonitoringSignificantLocationChanges()
            default:
                break
            }
        }
    }
}

private struct UnknownImportView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    private var isFutureVersion: Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let version = components.queryItems?.first(where: { $0.name == "v" })?.value,
              let v = Int(version) else { return false }
        return v > 1
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: isFutureVersion
                    ? "arrow.up.circle.fill"
                    : "exclamationmark.triangle.fill"
                )
                .font(.system(size: 60))
                .foregroundStyle(isFutureVersion ? .blue : .orange)

                Text(isFutureVersion
                    ? String(localized: "import.future_version.title")
                    : String(localized: "import.malformed.title")
                )
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

                Text(isFutureVersion
                    ? String(localized: "import.future_version.message")
                    : String(localized: "import.malformed.message")
                )
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "action.ok")) { dismiss() }
                }
            }
        }
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
