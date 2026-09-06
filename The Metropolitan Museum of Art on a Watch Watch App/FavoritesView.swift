import SwiftUI

@MainActor
struct FavoritesView: View {
    var store: FavoritesStore = .shared

    var body: some View {
        List {
            if let error = store.errorMessage {
                Section {
                    Text(error).font(.caption).foregroundStyle(.secondary)
                    Button("Retry Favorites") { store.reload() }
                }
            }
            if store.isLoaded && store.favorites.isEmpty {
                ContentUnavailableView("No Favorites", systemImage: "heart",
                                       description: Text("Save artwork from its details to keep it on this watch."))
            } else {
                ForEach(store.favorites) { object in
                    NavigationLink {
                        ObjectDetailView(objectDetails: object, favoritesStore: store)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(object.title.isEmpty ? "Untitled" : object.title)
                            if !object.artistDisplayName.isEmpty {
                                Text(object.artistDisplayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            do { try store.remove(object.objectID) } catch { }
                        } label: {
                            Label("Remove Favorite", systemImage: "heart.slash")
                        }
                    }
                }
            }
            Section {
                Text("Saved details stay on this watch. Images use a limited cache and may need a connection again.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Favorites")
    }
}
