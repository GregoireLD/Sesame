//
//  AboutView.swift
//  Sesame
//
//  Created by Greg on 2026-03-14.
//

import SwiftUI

struct AboutView: View {

    private let supportURL = URL(string: "https://sesame-app.com")!
    private let privacyURL = URL(string: "https://sesame-app.com/privacy.php")!
    private let tipURL = URL(string: "https://ko-fi.com/duvalparis")!
    
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("locationBannerDismissed") private var locationBannerDismissed = false
    @AppStorage("notificationBannerDismissed") private var notificationBannerDismissed = false

    @Environment(LocationManager.self) private var locationManager
    @Environment(KeyAvailabilityMonitor.self) private var keyMonitor
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showingOnboarding = false

    @AppStorage("showHiddenFeatures") private var showHiddenFeatures = false
    @State private var versionPressCount = 0

    @State private var countdown: Int? = nil
    @State private var countdownTask: Task<Void, Never>? = nil
    @State private var showingSimulateAlert = false
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var body: some View {
        NavigationStack {
            List {
                headerSection
                descriptionSection
                linksSection
                privacySection
                versionSection
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.close", systemImage: "xmark") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(Text("about.title"))
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showingOnboarding) {
                OnboardingView()
                    .environment(locationManager)
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: 12) {
                    Image("AppIconImage")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(radius: 4)
                    Text("app.name")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("about.tagline")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 8)
                Spacer()
            }
        }
        .listRowBackground(Color.clear)
    }

    private var descriptionSection: some View {
        Section {
            Text("about.description")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var linksSection: some View {
        Section {
            Link(destination: supportURL) {
                Label {
                    Text("about.support")
                } icon: {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            Link(destination: tipURL) {
                Label {
                    Text("about.tip")
                } icon: {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink)
                }
            }
            Button {
                locationBannerDismissed = false
                notificationBannerDismissed = false
            } label: {
                Label {
                    Text("about.reset_permissions")
                } icon: {
                    Image(systemName: "hand.raised.fill")
                        .foregroundStyle(.yellow)
                }
            }
            Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                Label {
                    Text("about.open_settings")
                } icon: {
                    Image(systemName: "gear")
                        .foregroundStyle(.gray)
                }
            }
        }
    }

    private var privacySection: some View {
        Section {
            Link(destination: privacyURL) {
                Label {
                    Text("about.privacy_policy")
                } icon: {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(.green)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Label {
                    Text("about.privacy_statement")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                        .font(.footnote)
                }
            }
        } header: {
            Text("about.privacy_header")
        }
    }

    private var versionSection: some View {
        Section {
            HStack {
                Text("about.version")
                Spacer()
                Text("\(appVersion) (\(buildNumber))")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: 1.0) {
                toggleHiddenFeatures()
            }

            if showHiddenFeatures {
                Button {
                    showingOnboarding = true
                } label: {
                    Label {
                        Text("about.replay_onboarding")
                    } icon: {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .foregroundStyle(.purple)
                    }
                }

                Button { } label: {
                    Label {
                        if let count = countdown {
                            Text("\(count)")
                                .monospacedDigit()
                                .contentTransition(.numericText(countsDown: true))
                        } else {
                            Text("Simulate broken key")
                        }
                    } icon: {
                        Image(systemName: "tree.fill")
                            .foregroundStyle(.red)
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in if countdown == nil { startCountdown() } }
                        .onEnded { _ in stopCountdown() }
                )
                .alert("Simulate broken key?", isPresented: $showingSimulateAlert) {
                    Button("Wait", role: .cancel) {
                        stopCountdown()
                    }
                    Button("Simulate", role: .destructive) {
                        keyMonitor.simulateBrokenKey()
                        dismiss()
                    }
                } message: {
                    Text("This will show the key unavailable banner as if iCloud Keychain had failed. The app will re-check periodically.")
                }
            }
        } footer: {
            HStack {
                Spacer()
                Text("about.credits")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Logic

    private func startCountdown() {
        countdown = 10
        countdownTask = Task { @MainActor in
            for i in stride(from: 10, through: 0, by: -1) {
                guard countdown != nil else { return }
                withAnimation { countdown = i }
                if i == 0 { break }
                try? await Task.sleep(for: .seconds(1))
            }
            guard countdown != nil else { return }
            countdown = nil
            showingSimulateAlert = true
        }
    }

    private func stopCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
        countdown = nil
    }

    private func toggleHiddenFeatures() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        showHiddenFeatures.toggle()

        // Second haptic pulse to confirm the new state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let confirm = UIImpactFeedbackGenerator(style: showHiddenFeatures ? .heavy : .light)
            confirm.impactOccurred()
        }
    }
}
