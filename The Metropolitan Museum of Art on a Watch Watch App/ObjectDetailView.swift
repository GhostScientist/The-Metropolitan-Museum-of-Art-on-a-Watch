//
//  ObjectDetailView.swift
//  The Tiny Met Watch App
//
//  Created by Dakota Kim on 4/2/24.
//

import AuthenticationServices
import SwiftUI

struct ObjectDetailView: View {
    let objectDetails: ObjectDetails

    /// watchOS has no browser, but an authentication session will present a
    /// web page. The session must be retained for as long as it is showing.
    @State private var webSession: ASWebAuthenticationSession?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                hero

                VStack(alignment: .leading, spacing: 2) {
                    Text(objectDetails.title)
                        .font(.system(.headline, design: .serif))
                    if !objectDetails.artistDisplayName.isEmpty {
                        Text(objectDetails.artistDisplayName)
                            .font(.subheadline)
                    }
                    if !objectDetails.artistDisplayBio.isEmpty {
                        Text(objectDetails.artistDisplayBio)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if !objectDetails.objectDate.isEmpty {
                        Text(objectDetails.objectDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    ObjectInfoSection(title: "Medium", content: objectDetails.medium)
                    ObjectInfoSection(title: "Dimensions", content: objectDetails.dimensions)
                    ObjectInfoSection(title: "Department", content: objectDetails.department)
                    ObjectInfoSection(title: "Culture", content: objectDetails.culture)
                    ObjectInfoSection(title: "Period", content: objectDetails.period)
                    ObjectInfoSection(title: objectDetails.geographyType, content: geography)
                    ObjectInfoSection(title: "Credit Line", content: objectDetails.creditLine)
                }

                if let url = URL(string: objectDetails.objectURL), !objectDetails.objectURL.isEmpty {
                    VStack(spacing: 6) {
                        Button {
                            openInWebSession(url)
                        } label: {
                            Label("View on metmuseum.org", systemImage: "safari")
                        }
                        .buttonStyle(.borderedProminent)

                        ShareLink(item: url) {
                            Label("Share", systemImage: "paperplane.fill")
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 4)
        }
        .containerBackground(Color.black, for: .navigation)
        .navigationTitle(objectDetails.objectName)
    }

    @ViewBuilder
    private var hero: some View {
        if objectDetails.primaryImageSmall.isEmpty {
            GalleryFrame {
                ArtworkPlaceholder(phase: .failure, caption: "No image available")
                    .aspectRatio(4 / 3, contentMode: .fit)
            }
        } else {
            NavigationLink(destination: ImageInspectView(imageURL: objectDetails.primaryImageSmall)) {
                GalleryFrame {
                    RemoteImage(url: objectDetails.primaryImageSmall, maxPixelSize: 640) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: { phase in
                        ArtworkPlaceholder(phase: phase)
                            .aspectRatio(4 / 3, contentMode: .fit)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func openInWebSession(_ url: URL) {
        let session = ASWebAuthenticationSession(url: url, callbackURLScheme: nil) { _, _ in
            webSession = nil
        }
        session.prefersEphemeralWebBrowserSession = true
        webSession = session
        session.start()
    }

    private var geography: String {
        [objectDetails.city, objectDetails.country]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}
