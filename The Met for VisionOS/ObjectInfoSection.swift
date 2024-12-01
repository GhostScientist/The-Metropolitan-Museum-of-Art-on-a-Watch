//
//  ObjectInfoSection.swift
//  The Tiny Met
//
//  Created by Dakota Kim on 12/1/24.
//


//
//  ObjectInfoSection.swift
//  The Tiny Met
//
//  Created by Dakota Kim on 10/28/24.
//

import SwiftUI

struct ObjectInfoSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(title):")
                .fontWeight(.bold)
            Text(content)
                .foregroundColor(.secondary)
        }
        .font(.subheadline)
    }
}
