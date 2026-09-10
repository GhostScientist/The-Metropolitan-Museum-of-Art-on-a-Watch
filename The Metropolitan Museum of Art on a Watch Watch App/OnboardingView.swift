//
//  OnboardingView.swift
//  The Tiny Met
//

import SwiftUI
import UIKit
import WatchKit

/// One room of the opening walk: a framed public-domain masterpiece and
/// the single thing its placard has to say.
struct OnboardingRoom: Identifiable, Equatable {
    let id: Int
    let numeral: String
    let credit: String
    let title: String
    let body: String
    let imageName: String

    static let all: [OnboardingRoom] = [
        OnboardingRoom(
            id: 1, numeral: "I",
            credit: "Van Gogh, 1889",
            title: "The Tiny Met",
            body: "Five thousand years of art, on your wrist.",
            imageName: "Onboarding-Welcome"
        ),
        OnboardingRoom(
            id: 2, numeral: "II",
            credit: "Hokusai, ca. 1830",
            title: "Walk the galleries",
            body: "Turn the crown to move from gallery to gallery. Tap a frame to step inside.",
            imageName: "Onboarding-Galleries"
        ),
        OnboardingRoom(
            id: 3, numeral: "III",
            credit: "Vermeer, ca. 1662",
            title: "Look closer",
            body: "Tap a work for its label, zoom with the crown, or search by name and artist.",
            imageName: "Onboarding-Search"
        ),
        OnboardingRoom(
            id: 4, numeral: "IV",
            credit: "Bruegel, 1565",
            title: "Hang one on your face",
            body: "Add the Featured Artwork complication for a new highlight through the day.",
            imageName: "Onboarding-Enter"
        ),
    ]
}

/// The museum opening for the day. The same matte-and-frame as the gallery
/// walk; the crown moves you room to room, and in each one the lights come
/// up on a masterpiece. The last room's button hands you straight into the
/// real galleries.
struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var selectedRoomID: Int? = OnboardingRoom.all.first?.id
    @State private var backdrop: UIImage?

    private let rooms = OnboardingRoom.all

    private var selectedRoom: OnboardingRoom {
        rooms.first { $0.id == selectedRoomID } ?? rooms[0]
    }

    private var isLastRoom: Bool {
        selectedRoom.id == rooms.last?.id
    }

    var body: some View {
        VStack(spacing: 4) {
            GalleryFrame {
                GeometryReader { proxy in
                    ScrollView(.vertical) {
                        LazyVStack(spacing: 0) {
                            ForEach(rooms) { room in
                                OnboardingArtwork(room: room, size: proxy.size)
                                    .onTapGesture { advance() }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .scrollPosition(id: $selectedRoomID)
                    .scrollIndicators(.hidden)
                    .contentMargins(0, for: .scrollContent)
                }
            }
            .frame(maxHeight: .infinity)

            placard

            // Fixed so the frame does not jump when the button replaces the numerals.
            footer
                .frame(height: 40)
        }
        .padding(.horizontal, 2)
        .background {
            AmbientBackdrop(image: backdrop)
        }
        .onChange(of: selectedRoomID, initial: true) { _, _ in
            updateBackdrop()
        }
    }

    private var placard: some View {
        VStack(spacing: 1) {
            Text(selectedRoom.title)
                .font(.system(.footnote, design: .serif, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            // Explicit size: outside a NavigationStack the caption text styles
            // resolve much larger on watchOS, which starved the frame of room.
            Text(selectedRoom.body)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .contentTransition(.opacity)
        .animation(.easeInOut(duration: 0.25), value: selectedRoomID)
    }

    @ViewBuilder
    private var footer: some View {
        if isLastRoom {
            Button {
                finish()
            } label: {
                Text("Enter the Museum")
                    .font(.system(.footnote, design: .serif, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.mini)
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
        } else {
            HStack(spacing: 6) {
                ForEach(rooms) { room in
                    Text(room.numeral)
                        .font(.system(size: 10, design: .serif))
                        .foregroundStyle(room.id == selectedRoom.id ? .primary : .quaternary)
                        .animation(.easeInOut(duration: 0.25), value: selectedRoomID)
                }
            }
            .transition(.opacity)
        }
    }

    private func advance() {
        if isLastRoom {
            finish()
            return
        }
        guard let index = rooms.firstIndex(of: selectedRoom), index + 1 < rooms.count else { return }
        withAnimation(.easeInOut(duration: 0.45)) {
            selectedRoomID = rooms[index + 1].id
        }
    }

    private func finish() {
        WKInterfaceDevice.current().play(.success)
        onFinish()
    }

    private func updateBackdrop() {
        let assetName = selectedRoom.imageName
        Task {
            backdrop = await ImageLoader.shared.thumbnail(named: assetName, maxPixelSize: 48)
        }
    }
}

/// A masterpiece revealed the way gallery lights come up: a fade in, and a
/// long, barely perceptible settle from a slight zoom.
private struct OnboardingArtwork: View {
    let room: OnboardingRoom
    let size: CGSize

    @State private var revealed = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(room.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .scaleEffect(revealed ? 1.0 : 1.10)
                .animation(.easeOut(duration: 9), value: revealed)
                .clipped()

            Text(room.credit)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(.black.opacity(0.45), in: Capsule())
                .padding(5)
        }
        .frame(width: size.width, height: size.height)
        .opacity(revealed ? 1 : 0)
        .animation(.easeOut(duration: 1.2), value: revealed)
        .contentShape(Rectangle())
        .onAppear { revealed = true }
    }
}

#Preview {
    OnboardingView {}
}
