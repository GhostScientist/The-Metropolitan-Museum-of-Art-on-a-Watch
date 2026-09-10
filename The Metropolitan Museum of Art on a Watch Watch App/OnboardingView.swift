//
//  OnboardingView.swift
//  The Tiny Met
//

import SwiftUI
import UIKit
import WatchKit

/// One room of the opening walk: a framed public-domain masterpiece and
/// the single thing its label has to say.
struct OnboardingRoom: Identifiable, Equatable {
    let id: Int
    let numeral: String
    let credit: String
    let title: String
    let message: String
    let imageName: String

    static let all: [OnboardingRoom] = [
        OnboardingRoom(
            id: 1, numeral: "I",
            credit: "Van Gogh, 1889",
            title: "The Tiny Met",
            message: "The Met's collection, on your wrist.",
            imageName: "Onboarding-Welcome"
        ),
        OnboardingRoom(
            id: 2, numeral: "II",
            credit: "Hokusai, ca. 1830",
            title: "Browse the galleries",
            message: "Turn the crown to browse. Tap a gallery to open it.",
            imageName: "Onboarding-Galleries"
        ),
        OnboardingRoom(
            id: 3, numeral: "III",
            credit: "Vermeer, ca. 1662",
            title: "Look closer",
            message: "Tap an artwork for details. Search by title or artist.",
            imageName: "Onboarding-Search"
        ),
        OnboardingRoom(
            id: 4, numeral: "IV",
            credit: "Bruegel, 1565",
            title: "Art on your watch face",
            message: "Add the Featured Artwork complication to your face.",
            imageName: "Onboarding-Enter"
        ),
    ]
}

/// The museum opening for the day. The same matte-and-frame as the gallery
/// walk, filled edge to edge by a masterpiece with its label set into the
/// lower edge. A button moves you room to room; the last one hands you
/// straight into the real galleries.
struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var selectedIndex = 0
    @State private var backdrop: UIImage?

    private let rooms = OnboardingRoom.all

    private var room: OnboardingRoom { rooms[selectedIndex] }
    private var isLastRoom: Bool { selectedIndex == rooms.count - 1 }

    var body: some View {
        VStack(spacing: 6) {
            GalleryFrame {
                OnboardingArtwork(room: room)
                    .id(room.id)
                    .transition(.opacity)
                    .contentShape(Rectangle())
                    .onTapGesture { advance() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Room marker and credit, kept out of the frame so the artwork
            // and its label have the whole picture on small watches.
            HStack(spacing: 5) {
                Text(room.numeral)
                    .font(.system(size: 10, weight: .semibold, design: .serif))
                Text("·")
                    .foregroundStyle(.tertiary)
                Text(room.credit)
                    .font(.system(size: 10))
            }
            .foregroundStyle(.secondary)
            .frame(height: 12)
            .contentTransition(.opacity)

            Button {
                advance()
            } label: {
                Text(isLastRoom ? "Get started" : "Next")
                    .font(.system(.footnote, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.mini)
            .frame(height: 36)
        }
        .padding(.horizontal, 2)
        .animation(.easeInOut(duration: 0.4), value: selectedIndex)
        .background {
            AmbientBackdrop(image: backdrop)
        }
        .onChange(of: selectedIndex, initial: true) { _, _ in
            updateBackdrop()
        }
    }

    private func advance() {
        if isLastRoom {
            WKInterfaceDevice.current().play(.success)
            onFinish()
        } else {
            WKInterfaceDevice.current().play(.click)
            selectedIndex += 1
        }
    }

    private func updateBackdrop() {
        let assetName = room.imageName
        Task {
            backdrop = await ImageLoader.shared.thumbnail(named: assetName, maxPixelSize: 48)
        }
    }
}

/// A masterpiece revealed the way gallery lights come up: a fade in and a
/// long, barely perceptible settle from a slight zoom, with its label set
/// into the lower edge.
private struct OnboardingArtwork: View {
    let room: OnboardingRoom

    @State private var revealed = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.clear
                .overlay {
                    Image(room.imageName)
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(revealed ? 1.0 : 1.08)
                        .animation(.easeOut(duration: 9), value: revealed)
                }
                .clipped()

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black.opacity(0.35), location: 0.45),
                    .init(color: .black.opacity(0.9), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(room.title)
                    .font(.system(.footnote, design: .serif, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                // Explicit size: outside a NavigationStack the caption text
                // styles resolve much larger on watchOS.
                Text(room.message)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 7)
            .shadow(color: .black.opacity(0.6), radius: 2, y: 1)

        }
        .opacity(revealed ? 1 : 0)
        .animation(.easeOut(duration: 1.0), value: revealed)
        .onAppear { revealed = true }
    }
}

#Preview {
    OnboardingView {}
}
