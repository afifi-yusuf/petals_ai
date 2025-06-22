//
//  PastLogView.swift
//  Petals.AI
//
//  Created by Rishi Hundia on 22/06/2025.
//

import Foundation
import SwiftUI
import SwiftData

public struct PastLogView: View {
    @Query(sort :\JournalLogModel.date, order: .reverse) var logs: [JournalLogModel]
    @State private var expandedLogID: UUID? = nil
    
    public var body: some View {
        NavigationStack {
            if logs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "book")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No past journal entries")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(logs) { log in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(log.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button(action: {
                                    toggle(log.id)
                                }) {
                                    Image(systemName: expandedLogID == log.id ? "chevron.up" : "chevron.down")
                                        .foregroundStyle(.blue)
                                }
                                .buttonStyle(.plain)
                            }
                            Text(previewText(for: log))
                                .font(.body)
                                .lineLimit(expandedLogID == log.id ? nil : 3)
                                .animation(.easeInOut, value: expandedLogID == log.id)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .navigationTitle("Past Journal Logs 😇 (You are doing GREAT)")
    }
    
    func toggle(_ id: UUID) {
        if expandedLogID == id {
            expandedLogID = nil
        } else {
            expandedLogID = id
        }
    }
    
    func previewText(for log: JournalLogModel) -> String {
        log.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}


#Preview {
    PastLogView()
}
