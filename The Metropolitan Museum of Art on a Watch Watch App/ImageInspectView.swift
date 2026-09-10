//
//  ImageInspectView.swift
//  The Tiny Met
//
//  Created by Dakota Kim on 10/28/24.
//

import SwiftUI

/// Full-screen look at a single image. The Digital Crown zooms, dragging
/// pans, and a double tap resets.
struct ImageInspectView: View {
    let imageURL: String

    @State private var scale: Double = 1.0
    @State private var offset: CGSize = .zero
    @State private var dragStart: CGSize = .zero

    private let minScale = 1.0
    private let maxScale = 5.0

    var body: some View {
        ZStack(alignment: .bottom) {
            RemoteImage(url: imageURL, maxPixelSize: 1200) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .onTapGesture(count: 2) {
                        withAnimation(.spring()) {
                            scale = minScale
                            offset = .zero
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: dragStart.width + value.translation.width,
                                    height: dragStart.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                dragStart = offset
                            }
                    )
            } placeholder: { phase in
                ArtworkPlaceholder(phase: phase)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            GlassEffectContainer {
                HStack {
                    Button {
                        withAnimation { scale = max(scale - 0.5, minScale) }
                    } label: {
                        Image(systemName: "minus")
                    }

                    Button {
                        withAnimation { scale = min(scale + 0.5, maxScale) }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .padding(.bottom, 4)
        }
        .focusable()
        .digitalCrownRotation(
            $scale,
            from: minScale,
            through: maxScale,
            by: 0.1,
            sensitivity: .low,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: scale) { _, newValue in
            if newValue <= minScale {
                withAnimation(.spring()) {
                    offset = .zero
                    dragStart = .zero
                }
            }
        }
        .containerBackground(Color.black, for: .navigation)
        .navigationBarTitleDisplayMode(.inline)
    }
}
