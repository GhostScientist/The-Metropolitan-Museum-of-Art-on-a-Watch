//
//  NetworkError.swift
//  The Tiny Met for visionOS
//
//  Created by Dakota Kim on 8/18/25.
//

import SwiftUI

extension Error {
    var isInternetConnectionError: Bool {
        let nsError = self as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorNotConnectedToInternet
    }
}