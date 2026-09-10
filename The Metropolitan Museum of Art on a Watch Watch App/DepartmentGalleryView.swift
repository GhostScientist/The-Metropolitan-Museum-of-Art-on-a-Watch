//
//  DepartmentGalleryView.swift
//  The Tiny Met Watch App
//
//  Created by Dakota Kim on 4/2/24.
//

import SwiftUI

/// One department's collection, hung as a column of artwork cards.
struct DepartmentGalleryView: View {
    let department: Department

    @State private var loader = ArtworkPageLoader()
    @State private var loadError: String?
    @State private var isLoadingIDs = false

    private let metMuseumClient = MetMuseumClient()

    var body: some View {
        Group {
            if loader.objects.isEmpty && (isLoadingIDs || loader.isLoading) {
                ProgressView()
            } else if let message = loadError ?? loader.errorMessage, loader.objects.isEmpty {
                ContentUnavailableView {
                    Label("Gallery closed", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again") { loadObjectIDs() }
                }
            } else if loader.objects.isEmpty {
                ContentUnavailableView("Nothing on display", systemImage: "photo.on.rectangle.angled")
            } else {
                List {
                    ArtworkRows(loader: loader)
                }
                .listStyle(.carousel)
            }
        }
        .navigationTitle(department.displayName)
        .containerBackground(Color.black, for: .navigation)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: SearchScope.department(department)) {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
        .onFirstAppear {
            loadObjectIDs()
        }
    }

    private func loadObjectIDs() {
        isLoadingIDs = true
        loadError = nil
        Task {
            do {
                let result = try await metMuseumClient.fetchObjects(departmentId: department.departmentId)
                isLoadingIDs = false
                await loader.replace(with: result.objectIDs)
            } catch {
                isLoadingIDs = false
                loadError = error.isInternetConnectionError
                    ? "You're offline. Reconnect to browse this gallery."
                    : "This gallery couldn't be loaded."
            }
        }
    }
}

#Preview {
    NavigationStack {
        DepartmentGalleryView(department: Department(departmentId: 11, displayName: "European Paintings"))
    }
}
