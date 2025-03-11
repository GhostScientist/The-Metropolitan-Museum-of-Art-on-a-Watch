import Foundation

public extension Error {
    /// Determines if the error is related to no internet connection
    var isInternetConnectionError: Bool {
        let nsError = self as NSError
        let networkErrors = [
            NSURLErrorNotConnectedToInternet,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorCannotConnectToHost,
            NSURLErrorCannotFindHost,
            NSURLErrorTimedOut
        ]
        
        return nsError.domain == NSURLErrorDomain && networkErrors.contains(nsError.code)
    }
} 