//
//  ScreenTimeListView.swift
//  Petals.AI
//
//  Created by Rishi Hundia on 02/08/2025.
//


// ScreenTimeListView.swift (Report Extension target)
import SwiftUI

struct ScreenTimeListView: View {
    struct Row: Identifiable {
        let id = UUID()
        let label: String
        let seconds: TimeInterval
    }

    let rows: [Row]

    var body: some View {
        List(rows) { row in
            HStack {
                Text(row.label)
                Spacer()
                Text(formatted(minutes: row.seconds / 60))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formatted(minutes: Double) -> String {
        "\(Int(minutes)) min"
    }
}
