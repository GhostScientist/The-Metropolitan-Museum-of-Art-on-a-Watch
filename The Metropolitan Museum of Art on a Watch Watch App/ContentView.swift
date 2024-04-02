import SwiftUI

struct ContentView: View {
    @State private var departments: [Department] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    private let metMuseumClient = MetMuseumClient()
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading")
                } else if errorMessage != nil {
                    Text(errorMessage!)
                } else {
                    List(departments, id: \.departmentId) { department in
                        NavigationLink(destination: Text(department.displayName)) {
                            Text(department.displayName)
                        }
                    }
                    .navigationTitle("Departments")
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
                print("Deps: \(departments)")
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

extension Error {
    var isInternetConnectionError: Bool {
        let nsError = self as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorNotConnectedToInternet
    }
}
