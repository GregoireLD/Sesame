//
//  OnboardingView.swift
//  Sesame
//
//  Created by Greg on 2026-03-15.
//

import SwiftUI

struct OnboardingView: View {

    @Environment(LocationManager.self) private var locationManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                WelcomePage()
                    .tag(0)
                HowItWorksPage()
                    .tag(1)
                PermissionsPage()
                    .tag(2)
                ExtraSecurityPage()
                    .tag(3)
                ReadyPage {
                    hasCompletedOnboarding = true
                    dismiss()
                }
                .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            HStack(spacing: 8) {
                ForEach(0..<5) { index in
                    Capsule()
                        .fill(index == currentPage
                            ? Color.primary
                            : Color.primary.opacity(0.3)
                        )
                        .frame(
                            width: index == currentPage ? 20 : 8,
                            height: 8
                        )
                        .animation(.spring(duration: 0.3), value: currentPage)
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Page 1: Welcome

private struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Image("onboarding.welcome")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280)
                .padding(.bottom, 40)
            VStack(spacing: 16) {
                Text("onboarding.welcome.title")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text("onboarding.welcome.subtitle")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Page 2: How It Works

private struct HowItWorksPage: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Image("onboarding.howitworks")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280)
                .padding(.bottom, 40)
            VStack(spacing: 24) {
                Text("onboarding.howitworks.title")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                VStack(alignment: .leading, spacing: 20) {
                    featureRow(
                        icon: "mappin.circle.fill",
                        color: .blue,
                        title: "onboarding.howitworks.feature1.title",
                        subtitle: "onboarding.howitworks.feature1.subtitle"
                    )
                    featureRow(
                        icon: "bell.fill",
                        color: .orange,
                        title: "onboarding.howitworks.feature2.title",
                        subtitle: "onboarding.howitworks.feature2.subtitle"
                    )
                    featureRow(
                        icon: "lock.shield.fill",
                        color: .green,
                        title: "onboarding.howitworks.feature3.title",
                        subtitle: "onboarding.howitworks.feature3.subtitle"
                    )
                }
                .padding(.horizontal, 32)
            }
            Spacer()
            Spacer()
        }
    }

    private func featureRow(
        icon: String,
        color: Color,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey
    ) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Page 3: Permissions

private struct PermissionsPage: View {

    @Environment(LocationManager.self) private var locationManager
    @State private var didRequestPermissions = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Image("onboarding.permissions")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280)
                .padding(.bottom, 40)
            VStack(spacing: 16) {
                Text("onboarding.permissions.title")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text("onboarding.permissions.subtitle")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Text("onboarding.permissions.note")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Spacer()
            VStack(spacing: 12) {
                if !didRequestPermissions {
                    Button {
                        requestPermissions()
                    } label: {
                        Text("onboarding.permissions.button")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 32)
                } else {
                    Label(
                        String(localized: "onboarding.permissions.granted"),
                        systemImage: "checkmark.circle.fill"
                    )
                    .foregroundStyle(.green)
                    .font(.headline)
                }
            }
            .padding(.bottom, 80)
        }
    }

    private func requestPermissions() {
        NotificationManager.shared.requestAuthorization()
        locationManager.requestAlwaysAuthorization()
        didRequestPermissions = true
    }
}

// MARK: - Page 4: Extra Security

private struct ExtraSecurityPage: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Image("onboarding.security")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280)
                .padding(.bottom, 40)
            VStack(spacing: 16) {
                Text("onboarding.security.title")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text("onboarding.security.subtitle")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                VStack(alignment: .leading, spacing: 12) {
                    Label(
                        String(localized: "onboarding.security.step1"),
                        systemImage: "1.circle.fill"
                    )
                    .foregroundStyle(.primary)
                    Label(
                        String(localized: "onboarding.security.step2"),
                        systemImage: "2.circle.fill"
                    )
                    .foregroundStyle(.primary)
                    Label(
                        String(localized: "onboarding.security.step3"),
                        systemImage: "3.circle.fill"
                    )
                    .foregroundStyle(.primary)
                }
                .font(.subheadline)
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Page 5: Ready

private struct ReadyPage: View {

    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Image("onboarding.ready")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280)
                .padding(.bottom, 40)
            VStack(spacing: 16) {
                Text("onboarding.ready.title")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text("onboarding.ready.subtitle")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Spacer()
            Button {
                onComplete()
            } label: {
                Text("onboarding.ready.button")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 80)
        }
    }
}
