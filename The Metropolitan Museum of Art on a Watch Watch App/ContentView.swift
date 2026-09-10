import SwiftUI
import UIKit

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
                                departmentBackground(for: department)
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

    /// Department artwork is bundled by department ID. Departments without a
    /// bundled image (currently 21, Modern Art) fall back to a gradient rather
    /// than rendering an empty background.
    @ViewBuilder
    private func departmentBackground(for department: Department) -> some View {
        let assetName = "\(department.departmentId)"
        if UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(
                colors: [.indigo, .black],
                startPoint: .top,
                endPoint: .bottom
            )
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
