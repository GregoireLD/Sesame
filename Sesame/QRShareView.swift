//
//  QRShareView.swift
//  Sesame
//
//  Created by Greg on 2026-03-16.
//

import SwiftUI

struct QRShareView: View {

    let accessCode: AccessCode
    @Environment(\.dismiss) private var dismiss

    @State private var qrImage: UIImage? = nil
    @State private var shareURL: URL? = nil
    @State private var showingShareSheet = false
    @State private var generationFailed = false
    
    @State private var includeRadius: Bool = false
    @State private var includeLocationDetails: Bool = false
    @State private var includeComment: Bool = false
    
    @AppStorage("showHiddenFeatures") private var showHiddenFeatures = false
    @AppStorage("qrIncludeCoordinates") private var includeCoordinates: Bool = true
    @AppStorage("qrUseLegacyScheme") private var useLegacyScheme: Bool = false
    @AppStorage("qrUsePlainFragment") private var usePlainFragment: Bool = false
    

    var body: some View {
        NavigationStack {
            List {
                qrSection
                optionsSection
                warningSection
                shareSection
            }
            .navigationTitle(Text("qr.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "action.cancel")) { dismiss() }
                }
            }
            .onAppear { generate() }
            .onChange(of: includeRadius) { _, _ in generate() }
            .onChange(of: includeLocationDetails) { _, _ in generate() }
            .onChange(of: includeComment) { _, _ in generate() }
            .sheet(isPresented: $showingShareSheet) {
                if let urlObj = shareURL {
                    ShareSheet(url: urlObj.absoluteString)
                }
            }
        }
    }

    // MARK: - Sections

    private var qrSection: some View {
        Section {
            HStack {
                Spacer()
                Group {
                    if let image = qrImage {
                        Image(uiImage: image)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                            .padding(16)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else if generationFailed {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.largeTitle)
                            Text("qr.generation_failed")
                                .foregroundStyle(.secondary)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 220, height: 220)
                    } else {
                        ProgressView()
                            .frame(width: 220, height: 220)
                    }
                }
                Spacer()
            }
            .listRowBackground(Color.clear)
            .padding(.vertical, 8)
        } header: {
            Text(accessCode.label ?? "")
                .font(.headline)
                .textCase(nil)
        }
    }

    private var warningSection: some View {
        Section {
            Label {
                Text("qr.warning")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundStyle(.orange)
            }
            if useLegacyScheme {
                Label {
                    Text("qr.warning.legacy_scheme")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "person.crop.circle.badge.xmark")
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var shareSection: some View {
        Section {
            Button {
                showingShareSheet = true
            } label: {
                Label {
                    Text("qr.share")
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color.listPrimary)
                }
            }
            .disabled(shareURL == nil)
        } footer: {
            Text("qr.share_footer")
                .font(.footnote)
        }
    }

    // MARK: - Logic

    private var optionsSection: some View {
        Section {
            Toggle(isOn: $includeRadius) {
                Label {
                    Text("qr.option.radius")
                } icon: {
                    Image(systemName: "location.circle.fill")
                        .foregroundStyle(Color.listPrimary)
                }
            }
            Toggle(isOn: $includeLocationDetails) {
                Label {
                    Text("qr.option.location_details")
                } icon: {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.orange)
                }
            }
            Toggle(isOn: $includeComment) {
                Label {
                    Text("qr.option.comment")
                } icon: {
                    Image(systemName: "text.bubble.fill")
                        .foregroundStyle(Color.listTertiary)
                }
            }
            if showHiddenFeatures {
                Toggle(isOn: Binding(
                    get: { !includeCoordinates },
                    set: { includeCoordinates = !$0; generate() }
                )) {
                    Label {
                        Text("qr.option.exclude_coordinates")
                    } icon: {
                        Image(systemName: "location.slash.fill")
                            .foregroundStyle(.purple)
                    }
                }
                Toggle(isOn: Binding(
                    get: { useLegacyScheme },
                    set: { useLegacyScheme = $0; generate() }
                )) {
                    Label {
                        Text("qr.option.legacy_scheme")
                    } icon: {
                        Image(systemName: "link.badge.plus")
                            .foregroundStyle(.purple)
                    }
                }
                Toggle(isOn: Binding(
                    get: { usePlainFragment },
                    set: { usePlainFragment = $0; generate() }
                )) {
                    Label {
                        Text("qr.option.plain_fragment")
                    } icon: {
                        Image(systemName: "text.alignleft")
                            .foregroundStyle(.purple)
                    }
                }
            }
        } header: {
            Text("qr.options_header")
        } footer: {
            Text("qr.options_footer")
        }
    }
    
    private func generate() {
        guard let url = ImportExport.url(
            for: accessCode,
            includeRadius: includeRadius,
            includeLocationDetails: includeLocationDetails,
            includeComment: includeComment,
            includeCoordinates: includeCoordinates,
            useLegacyScheme: useLegacyScheme,
            usePlainFragment: usePlainFragment
        ) else {
            generationFailed = true
            return
        }
        guard let image = ImportExport.image(for: url) else {
            generationFailed = true
            return
        }
        shareURL = url
        qrImage = image
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let url: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
