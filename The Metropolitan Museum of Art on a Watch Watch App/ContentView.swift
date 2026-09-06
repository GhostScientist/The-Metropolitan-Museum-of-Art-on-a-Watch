import SwiftUI

@MainActor
struct ContentView: View {
    @State private var departments: [Department] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var selectedTab = 0
    @State private var retryCount = 0
    
    private let metMuseumClient: any MetMuseumServing

    init(client: any MetMuseumServing = MetMuseumClient()) {
        metMuseumClient = client
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                NavigationLink {
                    FavoritesView()
                } label: {
                    Label("Favorites", systemImage: "heart.fill")
                }

                if isLoading {
                    ProgressView("Loading")
                } else if let errorMessage {
                    Text(errorMessage)
                    Button("Retry") { retryCount += 1 }
                } else if departments.isEmpty {
                    Text("No departments found")
                    Button("Retry") { retryCount += 1 }
                } else {
                    TabView(selection: $selectedTab) {
                        ForEach(departments.indices, id: \.self) { index in
                            let department = departments[index]
                            NavigationLink(destination: DepartmentListView(department: department, client: metMuseumClient)) {
                                Text(department.displayName as String)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                                    .padding()
                            }
                            .containerBackground(for: .tabView) {
                                Image("\(department.departmentId)")
                                    .resizable()
                                    .scaledToFill()
                            }
                            .tag(index)
                            
                        }
                        
                        .buttonStyle(PlainButtonStyle())
                    }
                    .tabViewStyle(.carousel)
                    
                }
            }
        }
        .task(id: retryCount) {
            if departments.isEmpty {
                await fetchDepartments()
            }
        }
    }
    
    private func fetchDepartments() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await metMuseumClient.fetchDepartments()
            try Task.checkCancellation()
            departments = response.departments
        } catch {
            guard !Task.isCancelled else { return }
            if error.isInternetConnectionError {
                errorMessage = "No connection. You can still browse Favorites."
            } else {
                errorMessage = "Could not load departments."
            }
        }
    }
}

#Preview {
    ContentView(client: PreviewMetMuseumClient())
}
