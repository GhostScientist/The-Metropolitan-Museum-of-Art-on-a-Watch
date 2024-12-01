//
//  CachedObjectDetails.swift
//  The Tiny Met
//
//  Created by Dakota Kim on 12/1/24.
//


//
//  CachedObjectDetails.swift
//  The Tiny Met
//
//  Created by Dakota Kim on 10/28/24.
//

import SwiftUI

final class CachedObjectDetails: NSObject {
    let details: ObjectDetails
    
    init(details: ObjectDetails) {
        self.details = details
        super.init()
    }
}

actor ObjectCache {
    static let shared = ObjectCache()
    private let cache = NSCache<NSNumber, CachedObjectDetails>()
    
    private init() {
        cache.countLimit = 100
    }
    
    func object(for id: Int) -> ObjectDetails? {
        cache.object(forKey: NSNumber(value: id))?.details
    }
    
    func cache(_ object: ObjectDetails) {
        let cached = CachedObjectDetails(details: object)
        cache.setObject(cached, forKey: NSNumber(value: object.objectID))
    }
}
