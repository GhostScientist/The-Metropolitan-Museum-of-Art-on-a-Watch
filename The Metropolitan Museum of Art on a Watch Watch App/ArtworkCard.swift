//
//  ArtworkCard.swift
//  The Tiny Met
//

import SwiftUI

/// A single artwork in a gallery list: the image with its label set into
/// the lower edge, the way a wall label sits beside a painting.
struct ArtworkCard: View {
    let object: ObjectDetails
    var secondary: String? = nil

    private let height: CGFloat = 100

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(url: object.primaryImageSmall, maxPixelSize: 480) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: { phase in
                ArtworkPlaceholder(phase: phase, caption: object.objectName)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.85)],
                startPoint: .init(x: 0.5, y: 0.35),
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 1) {
                Text(object.title)
                    .font(.system(.footnote, design: .serif, weight: .semibold))
                    .lineLimit(2)
                Text(secondary ?? defaultSecondary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 6)
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 0.5)
        )
    }

    private var defaultSecondary: String {
        if !object.artistDisplayName.isEmpty { return object.artistDisplayName }
        if !object.objectDate.isEmpty { return object.objectDate }
        return object.objectName
    }
}

/// The rows of a gallery list: one card per loaded object, a spinner while
/// the next page loads, and infinite paging as the last card appears.
struct ArtworkRows: View {
    let loader: ArtworkPageLoader
    var secondary: (ObjectDetails) -> String? = { _ in nil }

    var body: some View {
        ForEach(loader.objects) { object in
            NavigationLink(value: object) {
                ArtworkCard(object: object, secondary: secondary(object))
            }
            .buttonStyle(.plain)
            .listRowInsets(EdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 0))
            .listRowBackground(Color.clear)
            .onAppear {
                loader.loadMoreIfNeeded(after: object)
            }
        }

        if loader.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
        }
    }
}
