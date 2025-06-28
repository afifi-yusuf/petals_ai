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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \JournalLogModel.date, order: .reverse) var logs: [JournalLogModel]
    @State private var expandedLogID: UUID? = nil
    
    public var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark ? [
                    Color.purple.opacity(0.2),
                    Color.blue.opacity(0.1),
                    Color.black
                ] : [
                    Color.purple.opacity(0.1),
                    Color.blue.opacity(0.05),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Solid background overlay
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text("Back")
                                    .font(.headline)
                            }
                            .foregroundColor(.primary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(colors: [.mint, .teal], startPoint: .leading, endPoint: .trailing)
                            )
                        
                        VStack(spacing: 4) {
                            Text("Your Wellness Journey")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(colors: [.mint, .teal], startPoint: .leading, endPoint: .trailing)
                                )
                            
                            Text("\(logs.count) journal entries")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.bottom, 20)
                
                if logs.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.6))
                        
                        VStack(spacing: 8) {
                            Text("No Journal Entries Yet")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Start your wellness journey by writing your first journal entry")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Journal entries list
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(logs) { log in
                                JournalEntryCard(
                                    log: log,
                                    isExpanded: expandedLogID == log.id,
                                    onToggle: { toggle(log.id) }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    func toggle(_ id: UUID) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if expandedLogID == id {
                expandedLogID = nil
            } else {
                expandedLogID = id
            }
        }
    }
}

struct JournalEntryCard: View {
    let log: JournalLogModel
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with date and expand button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(log.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(log.date.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onToggle) {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Show Less" : "Show More")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.mint)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.mint)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.mint.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Journal content
            Text(log.text.trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.body)
                .lineSpacing(4)
                .lineLimit(isExpanded ? nil : 4)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            // Word count and reading time
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "text.word.spacing")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(wordCount()) words")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(readingTime()) min read")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private func wordCount() -> Int {
        log.text.split { $0.isWhitespace || $0.isNewline }.count
    }
    
    private func readingTime() -> Int {
        let words = wordCount()
        let wordsPerMinute = 200
        return max(1, words / wordsPerMinute)
    }
}

#Preview {
    PastLogView()
}
