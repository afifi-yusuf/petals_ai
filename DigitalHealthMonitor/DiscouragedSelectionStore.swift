//
//  DiscouragedSelectionStore.swift
//  Petals.AI
//
//  Created by Rishi Hundia on 01/08/2025.
//


import Foundation
import FamilyControls

enum DiscouragedSelectionStore {
            static let suite = "group.com.Petals-AI"     // <— your App Group ID
    static let key   = "discouragedSelection"

    static func save(_ selection: FamilyActivitySelection) {
        guard let data = try? JSONEncoder().encode(selection),
              let d = UserDefaults(suiteName: suite) else { return }
        d.set(data, forKey: key)
    }

    static func load() -> FamilyActivitySelection? {
        guard let d = UserDefaults(suiteName: suite),
              let data = d.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }
}
