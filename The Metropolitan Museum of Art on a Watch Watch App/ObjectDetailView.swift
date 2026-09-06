//
//  ObjectDetailView.swift
//  The Tiny Met Watch App
//
//  Created by Dakota Kim on 4/2/24.
//

import SwiftUI
import AuthenticationServices

@MainActor
struct ObjectDetailView: View {
    let objectDetails: ObjectDetails
    var favoritesStore: FavoritesStore = .shared
    @State private var favoriteMessage: String?
    @State private var isSavingImage = false
    @State private var previewTask: Task<Void, Never>?

    private var previewURL: String {
        ArtworkImageCache.imageURL(objectDetails.primaryImageSmall) != nil
            ? objectDetails.primaryImageSmall : objectDetails.primaryImage
    }

    private var inspectionURL: String {
        ArtworkImageCache.imageURL(objectDetails.primaryImage) != nil
            ? objectDetails.primaryImage : objectDetails.primaryImageSmall
    }

    private var detailsURL: URL? {
        guard let url = URL(string: objectDetails.objectURL),
              ["https", "http"].contains(url.scheme?.lowercased() ?? ""),
              url.host != nil else { return nil }
        return url
    }
    
    var body: some View {
            ScrollView {
                VStack(alignment: .center) {
                    if ArtworkImageCache.imageURL(previewURL) != nil {
                        ArtworkImageView(imageURL: previewURL)
                            .cornerRadius(10.0)
                        NavigationLink("Inspect Image") {
                            ImageInspectView(imageURL: inspectionURL, fallbackURL: previewURL)
                        }
                    } else {
                            VStack {
                                Image(systemName: "photo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.gray)
                                
                                Text("No image for this option")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }.padding()
                    }
                    
                    VStack(alignment: .leading) {
                        Text(objectDetails.title)
                            .font(.title3)
                            .fontWeight(.bold)

                        Button(action: toggleFavorite) {
                            Label(favoritesStore.contains(objectDetails.objectID) ? "Remove Favorite" : "Save Favorite",
                                  systemImage: favoritesStore.contains(objectDetails.objectID) ? "heart.fill" : "heart")
                        }
                        .disabled(!favoritesStore.isLoaded)
                        if isSavingImage {
                            ProgressView("Caching image")
                        }
                        if let message = favoriteMessage ?? favoritesStore.errorMessage {
                            Text(message).font(.caption).foregroundStyle(.secondary)
                        }
                        if !favoritesStore.isLoaded {
                            Button("Retry Favorites") { favoritesStore.reload() }
                        }
                        
                        if !objectDetails.artistDisplayBio.isEmpty {
                            Text(objectDetails.artistDisplayBio)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        ObjectInfoSection(title: "Date", content: objectDetails.objectDate)
                        
                        Divider()
                        
                        ObjectInfoSection(title: "Medium", content: objectDetails.medium)
                        
                        Divider()
                        
                        ObjectInfoSection(title: "Dimensions", content: objectDetails.dimensions)
                        
                        Divider()
                        
                        ObjectInfoSection(title: "Department", content: objectDetails.department)
                        
                        if !objectDetails.culture.isEmpty {
                            Divider()
                            ObjectInfoSection(title: "Culture", content: objectDetails.culture)
                        }
                        
                        if !objectDetails.period.isEmpty {
                            Divider()
                            ObjectInfoSection(title: "Period", content: objectDetails.period)
                        }
                        
                        if !objectDetails.geographyType.isEmpty {
                            Divider()
                            ObjectInfoSection(
                                title: objectDetails.geographyType,
                                content: "\(objectDetails.city), \(objectDetails.country)"
                            )
                        }
                        
                        Divider()
                        
                        ObjectInfoSection(title: "Credit Line", content: objectDetails.creditLine)
                        
                        if let url = detailsURL {
                            VStack {
                                Button {
                                    let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "") { _,_ in
                                    }
                                    session.prefersEphemeralWebBrowserSession = true
                                    session.start()
                                } label: {
                                    Text("View More Details")
                                }
                                ShareLink(item: url) {
                                    Label("Share", systemImage: "paperplane.fill")
                                }
                            }
                            
                        }
                        
                        
                        
                    }
                }
                .padding()
            }
        .containerBackground(.blue.gradient, for: .navigation)
        .navigationBarTitle(objectDetails.artistDisplayName)
        .onDisappear {
            previewTask?.cancel()
            isSavingImage = false
        }
    }

    private func toggleFavorite() {
        previewTask?.cancel()
        isSavingImage = false
        do {
            if favoritesStore.contains(objectDetails.objectID) {
                try favoritesStore.remove(objectDetails.objectID)
                favoriteMessage = "Favorite removed."
            } else {
                try favoritesStore.save(objectDetails)
                favoriteMessage = "Details saved on this watch."
                isSavingImage = true
                previewTask = Task { @MainActor in
                    let cached = await favoritesStore.cachePreview(for: objectDetails)
                    guard !Task.isCancelled else { return }
                    isSavingImage = false
                    favoriteMessage = cached
                        ? "Saved. Image cached for now; older images may be removed to save space."
                        : "Details saved. Image is not cached; reconnect to view it."
                }
            }
        } catch {
            favoriteMessage = "Could not change favorites: \(error.localizedDescription)"
        }
    }
}
