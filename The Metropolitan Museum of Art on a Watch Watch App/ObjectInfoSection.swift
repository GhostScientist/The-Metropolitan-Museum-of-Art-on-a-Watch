//
//  ObjectInfoSection.swift
//  The Tiny Met
//
//  Created by Dakota Kim on 10/28/24.
//

import SwiftUI

/// A labelled fact about an object. Renders nothing when there is nothing
/// to say, so callers can list every field without checking each one.
struct ObjectInfoSection: View {
    let title: String
    let content: String

    var body: some View {
        if !title.isEmpty, !content.isEmpty {
            VStack(alignment: .leading, spacing: 1) {
                Text(title.uppercased())
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                Text(content)
                    .font(.footnote)
            }
        }
    }
}
