//
//  OpenDepartmentControl.swift
//  The Tiny Met Widget
//
//  Created by Dakota Kim on 4/1/24.
//

import AppIntents
import SwiftUI
import WidgetKit

struct OpenTheTinyMetIntent: AppIntent {
    static let title: LocalizedStringResource = "Open The Tiny Met"
    static let description: IntentDescription = "Opens The Tiny Met app to browse the collection."
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct OpenTheTinyMetControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "OpenTheTinyMetControl") {
            ControlWidgetButton(action: OpenTheTinyMetIntent()) {
                Label("The Tiny Met", systemImage: "building.columns")
            }
        }
        .displayName("Open The Tiny Met")
        .description("Browse The Metropolitan Museum of Art collection.")
    }
}
