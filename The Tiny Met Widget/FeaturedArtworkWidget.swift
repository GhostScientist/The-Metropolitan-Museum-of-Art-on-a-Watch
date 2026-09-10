//
//  FeaturedArtworkWidget.swift
//  The Tiny Met Widget
//
//  Created by Dakota Kim on 4/1/24.
//

import SwiftUI
import UIKit
import WidgetKit

struct ArtworkEntry: TimelineEntry, Sendable {
    let date: Date
    let objectID: Int?
    let title: String
    let artistName: String
    let department: String
    let objectDate: String
    let image: UIImage?

    /// Opens the app straight to this object's detail view.
    var deepLink: URL? {
        objectID.flatMap { URL(string: "tinymet://object/\($0)") }
    }

    /// Van Gogh's Wheat Field with Cypresses, bundled, sized for `displaySize`.
    static func placeholder(fitting displaySize: CGSize) -> ArtworkEntry {
        ArtworkEntry(
            date: .now,
            objectID: 436535,
            title: "Wheat Field with Cypresses",
            artistName: "Vincent van Gogh",
            department: "European Paintings",
            objectDate: "1889",
            image: UIImage(named: "PlaceholderArtwork").flatMap { ArtworkEntry.artwork($0, fitting: displaySize) }
        )
    }

    /// WidgetKit rejects images much larger than the widget itself, so the
    /// artwork is rendered to the widget's display size. 1.8x rather than the
    /// screen's 2x keeps the pixel area under WidgetKit's limit on every
    /// watch size while staying sharp.
    static func artwork(_ image: UIImage, fitting displaySize: CGSize) -> UIImage? {
        ImageLoader.cover(image, pointSize: displaySize, scale: 1.8)
    }
}

struct ArtworkTimelineProvider: TimelineProvider {
    private let client = MetMuseumClient()

    func placeholder(in context: Context) -> ArtworkEntry {
        .placeholder(fitting: context.displaySize)
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (ArtworkEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder(fitting: context.displaySize))
            return
        }
        let displaySize = context.displaySize
        Task {
            completion(await fetchRandomHighlight(fitting: displaySize))
        }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<ArtworkEntry>) -> Void) {
        let displaySize = context.displaySize
        Task {
            let entry = await fetchRandomHighlight(fitting: displaySize)
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: entry.date)
                ?? entry.date.addingTimeInterval(4 * 60 * 60)
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }

    /// A random highlighted object that has an image. Only objects whose
    /// image actually downloads are eligible, so the complication never
    /// shows an empty frame.
    private func fetchRandomHighlight(fitting displaySize: CGSize) async -> ArtworkEntry {
        var query = SearchQuery(query: "*")
        query.isHighlight = true
        query.hasImages = true

        guard let result = try? await client.searchObjects(query: query) else {
            return .placeholder(fitting: displaySize)
        }

        for objectID in result.objectIDs.shuffled().prefix(4) {
            guard let details = try? await client.fetchObjectDetails(objectID: objectID),
                  !details.primaryImageSmall.isEmpty,
                  let source = await ImageLoader.shared.image(for: details.primaryImageSmall, maxPixelSize: 720),
                  let image = ArtworkEntry.artwork(source, fitting: displaySize)
            else { continue }

            return ArtworkEntry(
                date: .now,
                objectID: details.objectID,
                title: details.title,
                artistName: details.artistDisplayName,
                department: details.department,
                objectDate: details.objectDate,
                image: image
            )
        }
        return .placeholder(fitting: displaySize)
    }
}

struct FeaturedArtworkWidgetView: View {
    let entry: ArtworkEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetContentMargins) private var margins

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                Label(entry.title, systemImage: "paintpalette")
                    .padding(margins)
            case .accessoryCorner:
                Image(systemName: "building.columns")
                    .font(.title3)
                    .widgetLabel {
                        Text(entry.title)
                    }
                    .padding(margins)
            default:
                rectangular
            }
        }
        .widgetURL(entry.deepLink)
    }

    /// The large rectangle: the artwork edge to edge, with its label set
    /// into the lower edge. Kept in the content rather than the container
    /// background so it also renders on watch faces, which drop backgrounds.
    private var rectangular: some View {
        ZStack(alignment: .bottomLeading) {
            Color.clear
                .overlay {
                    if let image = entry.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        LinearGradient(
                            colors: [Color(red: 0.24, green: 0.20, blue: 0.30), .black],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
                .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.8)],
                startPoint: .init(x: 0.5, y: 0.3),
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 0) {
                Text(entry.title)
                    .font(.system(.footnote, design: .serif, weight: .semibold))
                    .lineLimit(2)
                if !entry.artistName.isEmpty {
                    Text(entry.artistName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(ContainerRelativeShape())
    }
}

struct FeaturedArtworkWidget: Widget {
    let kind = "FeaturedArtworkWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ArtworkTimelineProvider()) { entry in
            FeaturedArtworkWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Featured Artwork")
        .description("A highlighted work from The Met, refreshed through the day. Tap to see its details.")
        .supportedFamilies([
            .accessoryInline,
            .accessoryRectangular,
            .accessoryCorner,
        ])
        .contentMarginsDisabled()
    }
}

#Preview(as: .accessoryRectangular) {
    FeaturedArtworkWidget()
} timeline: {
    ArtworkEntry.placeholder(fitting: CGSize(width: 194, height: 80.5))
}
