//
//  LocationManager.swift
//  Sesame
//
//  Created by Greg on 2026-03-12.
//

import Foundation
import CoreLocation
import UserNotifications
import SwiftData

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {

    private let clManager = CLLocationManager()
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var currentLocation: CLLocation? = nil
    
    // Reference to SwiftData context for querying fresh data
    var modelContext: ModelContext?

    // MARK: - Constants

    private let activeSetSize = 15
    private let dynamicThreshold = 15
    private let safetyGeofenceIdentifier = "com.paris.duval.sesame.safety"

    // MARK: - State

    // Cache only IDs of the active set to detect changes
    private var activeSetIDs: Set<UUID> = []
    private var isDynamic: Bool = false

    override init() {
        super.init()
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = clManager.authorizationStatus
    }

    // MARK: - Authorization

    func requestAlwaysAuthorization() {
        clManager.requestAlwaysAuthorization()
    }

    // MARK: - Location Updates

    func startUpdatingLocation() {
        clManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        clManager.stopUpdatingLocation()
    }

    func startMonitoringSignificantLocationChanges() {
        clManager.startMonitoringSignificantLocationChanges()
    }

    // MARK: - Data Fetching

    /// Fetches all non-silenced access codes with valid coordinates from SwiftData.
    private func fetchAllAccessCodes() -> [AccessCode]? {
        guard let context = modelContext else { return nil }
        
        let descriptor = FetchDescriptor<AccessCode>(
            predicate: #Predicate<AccessCode> { code in
                code.isSilenced != true
                && code.latitude != nil
                && code.longitude != nil
            },
            sortBy: [SortDescriptor(\.label)]
        )
        
        return try? context.fetch(descriptor)
    }

    // MARK: - Public Interface

    /// Called on app launch and whenever the full entry list changes.
    func restartAllMonitoring(context: ModelContext) {
        self.modelContext = context
        
        // Fetch fresh data from SwiftData
        guard let accessCodes = fetchAllAccessCodes() else { return }
        
        stopAllMonitoring()

        if accessCodes.count <= dynamicThreshold {
            // Simple mode — monitor everything directly
            isDynamic = false
            for code in accessCodes {
                startMonitoring(accessCode: code)
            }
        } else {
            // Dynamic mode — monitor only the closest 15
            isDynamic = true
            recalculateActiveSet()
        }
    }

    /// Called when a single entry is added.
    func startMonitoring(accessCode: AccessCode) {
        guard let lat = accessCode.latitude,
              let lon = accessCode.longitude,
              let radius = accessCode.radiusMeters,
              let id = accessCode.id else { return }

        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            radius: radius,
            identifier: id.uuidString
        )
        region.notifyOnEntry = true
        region.notifyOnExit = false
        clManager.startMonitoring(for: region)
    }

    /// Called when a single entry is deleted.
    func stopMonitoring(accessCode: AccessCode) {
        guard let id = accessCode.id else { return }
        let targetID = id.uuidString
        for region in clManager.monitoredRegions {
            if region.identifier == targetID {
                clManager.stopMonitoring(for: region)
            }
        }
        // If we were in dynamic mode, recalculate
        if isDynamic {
            recalculateActiveSet()
        }
    }

    // MARK: - Dynamic Geofencing

    /// Recalculates which 15 entries to monitor based on current location.
    /// Falls back to first 15 alphabetically if location is unavailable.
    func recalculateActiveSet() {
        guard let allAccessCodes = fetchAllAccessCodes(), !allAccessCodes.isEmpty else {
            return
        }

        let sorted: [AccessCode]
        if let location = currentLocation {
            sorted = allAccessCodes.sorted {
                let loc0 = CLLocation(
                    latitude: $0.latitude ?? 0,
                    longitude: $0.longitude ?? 0
                )
                let loc1 = CLLocation(
                    latitude: $1.latitude ?? 0,
                    longitude: $1.longitude ?? 0
                )
                // Sort by distance to near edge rather than centre, so entries with
                // large radii that we're close to triggering rank above distant entries
                // with small radii whose centres happen to be closer.
                let edge0 = max(0, location.distance(from: loc0) - ($0.radiusMeters ?? 100))
                let edge1 = max(0, location.distance(from: loc1) - ($1.radiusMeters ?? 100))
                return edge0 < edge1
            }
        } else {
            // No location available — sort alphabetically as fallback
            sorted = allAccessCodes.sorted {
                ($0.label ?? "") < ($1.label ?? "")
            }
        }

        let newActiveSet = Array(sorted.prefix(activeSetSize))
        let newActiveIDs = Set(newActiveSet.compactMap { $0.id })
        
        // Only update if the active set changed
        guard newActiveIDs != activeSetIDs else { return }
        
        activeSetIDs = newActiveIDs

        // Stop all entry geofences
        stopAllEntryMonitoring()

        // Start monitoring the new active set
        for code in newActiveSet {
            startMonitoring(accessCode: code)
        }

        // Update the safety geofence
        updateSafetyGeofence(activeSet: newActiveSet)
    }

    private func updateSafetyGeofence(activeSet: [AccessCode]) {
        // Remove existing safety geofence
        removeSafetyGeofence()

        guard let location = currentLocation,
              !activeSet.isEmpty else { return }

        // Radius = distance to the furthest entry in the active set
        // Safety geofence radius = distance to the near edge of the furthest
        // monitored entry, scaled by 0.95. This triggers recalculation just
        // before the user enters the last bubble in the active set — ensuring
        // new entries beyond it are registered before they're needed, rather
        // than after the current list is exhausted.
        let furthestDistance = activeSet.compactMap { code -> CLLocationDistance? in
            guard let lat = code.latitude, let lon = code.longitude else { return nil }
            let codeLoc = CLLocation(latitude: lat, longitude: lon)
            let centreDistance = location.distance(from: codeLoc)
            let radius = code.radiusMeters ?? 100
            return max(0, centreDistance - radius)
        }.max() ?? 500

        // 0.95 so recalculation triggers slightly before reaching
        // the edge of coverage, not after
        let safetyRadius = min(furthestDistance * 0.95, CLLocationDistanceMax)

        let safetyRegion = CLCircularRegion(
            center: location.coordinate,
            radius: safetyRadius,
            identifier: safetyGeofenceIdentifier
        )
        safetyRegion.notifyOnEntry = false
        safetyRegion.notifyOnExit = true
        clManager.startMonitoring(for: safetyRegion)
    }

    private func removeSafetyGeofence() {
        for region in clManager.monitoredRegions {
            if region.identifier == safetyGeofenceIdentifier {
                clManager.stopMonitoring(for: region)
            }
        }
    }

    private func stopAllEntryMonitoring() {
        for region in clManager.monitoredRegions {
            if region.identifier != safetyGeofenceIdentifier {
                clManager.stopMonitoring(for: region)
            }
        }
    }

    private func stopAllMonitoring() {
        for region in clManager.monitoredRegions {
            clManager.stopMonitoring(for: region)
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedAlways ||
           manager.authorizationStatus == .authorizedWhenInUse {
            startUpdatingLocation()
            startMonitoringSignificantLocationChanges()
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        currentLocation = locations.last
    }

    func locationManager(
        _ manager: CLLocationManager,
        didEnterRegion region: CLRegion
    ) {
        guard let circularRegion = region as? CLCircularRegion else { return }

        // Ignore the safety geofence entry — we only care about exit
        guard circularRegion.identifier != safetyGeofenceIdentifier else { return }

        NotificationManager.shared.sendNotification(
            forRegionIdentifier: circularRegion.identifier
        )
    }

    func locationManager(
        _ manager: CLLocationManager,
        didExitRegion region: CLRegion
    ) {
        guard let circularRegion = region as? CLCircularRegion else { return }

        // Safety geofence exit → recalculate active set
        if circularRegion.identifier == safetyGeofenceIdentifier {
            // Request a single fresh location fix before recalculating
            clManager.requestLocation()
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didDetermineState state: CLRegionState,
        for region: CLRegion
    ) {
        // When significant location change fires, iOS calls this for all regions
        // We use it as an additional recalculation trigger in dynamic mode
        if isDynamic && region.identifier == safetyGeofenceIdentifier
            && state == .outside {
            clManager.requestLocation()
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        print("LocationManager error: \(error.localizedDescription)")
    }

    func locationManager(
        _ manager: CLLocationManager,
        monitoringDidFailFor region: CLRegion?,
        withError error: Error
    ) {
        print("Monitoring failed for region \(region?.identifier ?? "unknown"): \(error.localizedDescription)")
    }
}
