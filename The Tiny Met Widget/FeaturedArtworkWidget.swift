//
//  FeaturedArtworkWidget.swift
//  The Tiny Met Widget
//
//  Created by Dakota Kim on 4/1/24.
//

import SwiftUI
import WidgetKit

struct ArtworkEntry: TimelineEntry {
    let date: Date
    let title: String
    let artistName: String
    let department: String
    let objectDate: String
    let isPlaceholder: Bool

    static let placeholder = ArtworkEntry(
        date: .now,
        title: "Wheat Field with Cypresses",
        artistName: "Vincent van Gogh",
        department: "European Paintings",
        objectDate: "1889",
        isPlaceholder: true
    )
}

struct ArtworkTimelineProvider: TimelineProvider {
    private let client = MetMuseumClient()

    func placeholder(in context: Context) -> ArtworkEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (ArtworkEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        Task {
            let entry = await fetchRandomHighlight()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ArtworkEntry>) -> Void) {
        Task {
            let entry = await fetchRandomHighlight()
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: entry.date)!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    private func fetchRandomHighlight() async -> ArtworkEntry {
        do {
            let result = try await client.searchObjects(
                query: {
                    var q = SearchQuery(query: "*")
                    q.isHighlight = true
                    q.hasImages = true
                    return q
                }()
            )

            guard !result.objectIDs.isEmpty else {
                return .placeholder
            }

            let randomID = result.objectIDs.randomElement()!
            let details = try await client.fetchObjectDetails(objectID: randomID)

            return ArtworkEntry(
                date: .now,
                title: details.title,
                artistName: details.artistDisplayName,
                department: details.department,
                objectDate: details.objectDate,
                isPlaceholder: false
            )
        } catch {
            return .placeholder
        }
    }
}

struct FeaturedArtworkWidgetView: View {
    let entry: ArtworkEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryInline:
            Label(entry.title, systemImage: "paintpalette")
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "paintpalette.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(entry.department)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text(entry.title)
                    .font(.headline)
                    .lineLimit(2)
                if !entry.artistName.isEmpty {
                    Text(entry.artistName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .accessoryCorner:
            Image(systemName: "building.columns")
                .font(.title3)
                .widgetLabel {
                    Text(entry.title)
                }
        default:
            VStack(alignment: .leading) {
                Text(entry.title)
                    .font(.caption)
                    .lineLimit(2)
                if !entry.artistName.isEmpty {
                    Text(entry.artistName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
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
        .description("Discover a highlighted artwork from The Metropolitan Museum of Art.")
        .supportedFamilies([
            .accessoryInline,
            .accessoryRectangular,
            .accessoryCorner,
        ])
    }
}

#Preview(as: .accessoryRectangular) {
    FeaturedArtworkWidget()
} timeline: {
    ArtworkEntry.placeholder
}
