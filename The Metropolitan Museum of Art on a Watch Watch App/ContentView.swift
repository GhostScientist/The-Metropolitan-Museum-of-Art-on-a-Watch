import SwiftUI

struct ContentView: View {
    @State private var departments: [Department] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var selectedTab = 0

    private let metMuseumClient = MetMuseumClient()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading")
                } else if let errorMessage {
                    Text(errorMessage)
                } else {
                    TabView(selection: $selectedTab) {
                        ForEach(departments.indices, id: \.self) { index in
                            let department = departments[index]
                            NavigationLink(destination: DepartmentListView(department: department)) {
                                Text(department.displayName as String)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                                    .padding()
                                    .tag(index)
                            }
                            .containerBackground(for: .tabView) {
                                Image("\(department.departmentId)")
                                    .resizable()
                                    .scaledToFill()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .tabViewStyle(.verticalPage)
                }
            }
        }
        .onAppear {
            fetchDepartments()
        }
    }

    private func fetchDepartments() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                departments = try await metMuseumClient.fetchDepartments().departments
                isLoading = false
            } catch {
                if error.isInternetConnectionError {
                    errorMessage = "Awwww no wifi UWU"
                } else {
                    errorMessage = "Failed to fetch departments"
                }
                isLoading = false
            }
        }
    }
}
