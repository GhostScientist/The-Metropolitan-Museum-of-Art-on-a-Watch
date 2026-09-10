//
//  ArtworkSearchView.swift
//  The Tiny Met
//

import SwiftUI

enum SearchScope: Hashable {
    case collection
    case department(Department)

    var title: String {
        switch self {
        case .collection: "Search"
        case .department(let department): department.displayName
        }
    }

    var departmentId: Int? {
        if case .department(let department) = self { return department.departmentId }
        return nil
    }
}

struct SearchSuggestion: Identifiable {
    let label: String
    let query: SearchQuery
    var id: String { label }

    init(_ label: String, query: SearchQuery? = nil) {
        self.label = label
        self.query = query ?? SearchQuery(query: label)
    }

    static func highlights(in departmentId: Int?) -> SearchSuggestion {
        var query = SearchQuery(query: "*")
        query.isHighlight = true
        query.departmentId = departmentId
        return SearchSuggestion("Highlights", query: query)
    }

    static func suggestions(for scope: SearchScope) -> [SearchSuggestion] {
        let departmentId = scope.departmentId
        var list = [highlights(in: departmentId)]
        switch scope {
        case .collection:
            list += ["Van Gogh", "Armor", "Egypt", "Portrait", "Cats"].map { SearchSuggestion($0) }
        case .department:
            list += ["Portrait", "Landscape", "Gold", "Animals"].map { SearchSuggestion($0) }
        }
        return list
    }
}

/// Search the whole collection or a single department. Typing on a watch is
/// effortful, so an empty field offers a few good starting points, and
/// results favour objects that have an image to show.
struct ArtworkSearchView: View {
    let scope: SearchScope

    @State private var text = ""
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var searchError: String?
    @State private var loader = ArtworkPageLoader()

    private let client = MetMuseumClient()

    var body: some View {
        List {
            TextField("Search", text: $text)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .onSubmit { search(SearchQuery(query: text)) }

            if isSearching {
                HStack(spacing: 6) {
                    ProgressView()
                    Text("Searching…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            } else if let message = searchError ?? loader.errorMessage, loader.objects.isEmpty {
                ContentUnavailableView(message, systemImage: "exclamationmark.triangle")
                    .listRowBackground(Color.clear)
            } else if hasSearched && loader.objects.isEmpty && !loader.isLoading {
                ContentUnavailableView.search(text: text)
                    .listRowBackground(Color.clear)
            } else if hasSearched {
                if loader.totalCount > 0 {
                    Text("\(loader.totalCount) works")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }
                ArtworkRows(loader: loader, secondary: secondaryLine)
            } else {
                Section {
                    ForEach(SearchSuggestion.suggestions(for: scope)) { suggestion in
                        Button {
                            text = suggestion.label
                            search(suggestion.query)
                        } label: {
                            Label {
                                Text(suggestion.label)
                                    .font(.system(.body, design: .serif))
                            } icon: {
                                Image(systemName: suggestion.label == "Highlights" ? "sparkles" : "magnifyingglass")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Try")
                }
            }
        }
        .navigationTitle(scope.title)
        .containerBackground(Color.black, for: .navigation)
    }

    private func secondaryLine(for object: ObjectDetails) -> String? {
        guard case .collection = scope else { return nil }
        let parts = [object.artistDisplayName, object.department].filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func search(_ base: SearchQuery) {
        var query = base
        query.query = query.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.query.isEmpty else { return }
        if query.departmentId == nil {
            query.departmentId = scope.departmentId
        }

        isSearching = true
        hasSearched = true
        searchError = nil

        Task {
            do {
                // Prefer objects with images; fall back to everything if that yields nothing.
                var withImages = query
                withImages.hasImages = true
                var result = try await client.searchObjects(query: withImages)
                if result.objectIDs.isEmpty {
                    result = try await client.searchObjects(query: query)
                }
                isSearching = false
                await loader.replace(with: result.objectIDs)
            } catch {
                isSearching = false
                searchError = error.isInternetConnectionError
                    ? "You're offline. Reconnect to search the collection."
                    : "Search isn't available right now."
            }
        }
    }
}

#Preview {
    NavigationStack {
        ArtworkSearchView(scope: .collection)
    }
}
