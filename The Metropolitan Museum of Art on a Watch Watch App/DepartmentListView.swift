import SwiftUI

@MainActor
struct DepartmentListView: View {
    @State private var model: DepartmentBrowser
    @State private var searchText = ""
    let department: Department

    init(department: Department, client: any MetMuseumServing = MetMuseumClient()) {
        self.department = department
        _model = State(initialValue: DepartmentBrowser(departmentID: department.departmentId, client: client))
    }

    var body: some View {
        List {
            ForEach(model.objects) { object in
                NavigationLink(destination: ObjectDetailView(objectDetails: object)) {
                    Text(object.title)
                }
                .onAppear {
                    if object.id == model.objects.last?.id {
                        model.loadMore()
                    }
                }
            }

            if model.isLoading {
                ProgressView("Loading")
            } else if let error = model.errorMessage {
                Text(error)
                Button("Retry") { model.retry() }
            } else if model.hasLoaded && model.objects.isEmpty {
                Text(model.isSearching ? "No results found" : "No objects available")
            } else if model.hasMore {
                Button("Load more") { model.loadMore() }
            }
        }
        .navigationTitle(department.displayName)
        .task {
            await model.loadIfNeeded()?.value
        }
        .searchable(text: $searchText, prompt: "Search objects")
        .onSubmit(of: .search) {
            model.search(searchText)
        }
        .onChange(of: searchText) { _, value in
            if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                model.search("")
            }
        }
    }
}

#Preview {
    DepartmentListView(department: PreviewMetMuseumClient.department, client: PreviewMetMuseumClient())
}
