//
//  GalleryFrame.swift
//  The Tiny Met
//

import SwiftUI

/// A museum-style matte and hairline frame around a piece of content.
///
/// Deliberately restrained: a dark, slightly warm matte with a soft
/// highlight along the top-left edge, so artwork reads as hung on a wall
/// rather than pasted into a card.
struct GalleryFrame<Content: View>: View {
    var cornerRadius: CGFloat = 14
    var matte: CGFloat = 5
    @ViewBuilder let content: () -> Content

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        content()
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius - matte, style: .continuous))
            .padding(matte)
            .background(shape.fill(Color(red: 0.13, green: 0.12, blue: 0.11)))
            .overlay(
                shape.strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.45), .white.opacity(0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            )
    }
}

/// Shared look for artwork that has no image, or is still loading.
struct ArtworkPlaceholder: View {
    let phase: RemoteImagePhase
    var caption: String = ""

    var body: some View {
        ZStack {
            Rectangle().fill(Color(white: 0.16))
            VStack(spacing: 4) {
                Image(systemName: phase == .failure ? "photo.on.rectangle.angled" : "photo")
                    .font(.title3)
                    .foregroundStyle(.quaternary)
                if phase == .failure, !caption.isEmpty {
                    Text(caption)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }
        }
    }
}
