//
//  DigitalWellnessView.swift
//  Petals.AI
//
//  Created by Yusuf Afifi on 26/07/2025.
//


import SwiftUI
import FamilyControls

// MARK: - Digital Wellness View
struct DigitalWellnessView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @State private var selectedTimeframe: TimeFrame = .today
    @State private var showingAppLimits = false
    
    enum TimeFrame: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header Stats
                        VStack(spacing: 16) {
                            // Time selector
                            Picker("Timeframe", selection: $selectedTimeframe) {
                                ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                                    Text(timeframe.rawValue).tag(timeframe)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal, 4)
                        }
                        .padding(.horizontal, 20)
                        
                        // Main Stats Cards
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            
                            DigitalStatCard(
                                title: "Screen Time",
                                value: "4h 23m",
                                subtitle: "12% less than yesterday",
                                icon: "iphone",
                                color: .orange,
                                trend: .down
                            )
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            
                            DigitalStatCard(
                                title: "Pickups",
                                value: "47",
                                subtitle: "8 more than yesterday",
                                icon: "hand.tap",
                                color: .red,
                                trend: .up
                            )
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            
                            DigitalStatCard(
                                title: "First Pickup",
                                value: "7:32 AM",
                                subtitle: "15 min later than usual",
                                icon: "sunrise",
                                color: .green,
                                trend: .neutral
                            )
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            
                            DigitalStatCard(
                                title: "Last Use",
                                value: "11:15 PM",
                                subtitle: "30 min earlier than usual",
                                icon: "moon",
                                color: .indigo,
                                trend: .neutral
                            )
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .padding(.horizontal, 20)
                        
                        // App Usage Breakdown
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Top Apps Today")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                AppUsageRow(appName: "Social Media", time: "1h 45m", percentage: 0.4, color: .blue)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                AppUsageRow(appName: "Entertainment", time: "1h 12m", percentage: 0.28, color: .purple)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                AppUsageRow(appName: "Productivity", time: "58m", percentage: 0.22, color: .green)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                AppUsageRow(appName: "Games", time: "28m", percentage: 0.1, color: .orange)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Wellness Insights
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Wellness Insights")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                            
//                            VStack(spacing: 12) {
//                                ForEach(screenTimeManager.getDigitalWellnessInsights(), id: \.self) { insight in
//                                    InsightCard(insight: insight)
//                                        .background(.ultraThinMaterial)
//                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
//                                }
//                            }
//                            .padding(.horizontal, 20)
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: {
                                showingAppLimits = true
                            }) {
                                HStack {
                                    Image(systemName: "timer")
                                        .foregroundColor(.white)
                                    
                                    Text("Set App Limits")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.7))
                                        .font(.caption)
                                }
                                .padding(16)
                                .background(
                                    LinearGradient(
                                        colors: [.orange, .orange.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                            }
                            
                            Button(action: {
                                // Digital detox action
                            }) {
                                HStack {
                                    Image(systemName: "leaf")
                                        .foregroundColor(.green)
                                    
                                    Text("Start Digital Detox")
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.green.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 30)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Digital Balance")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAppLimits) {
                BlockAppPicker()
            }
            .onAppear {
                Task {
                    do {
                        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    } catch {
                        // Handle the error appropriately
                        print("Failed to request authorization for Family Controls: \(error)")
                    }
                }
            }
        }
        .environment(\.colorScheme, colorScheme)
    }
    
    @Environment(\.colorScheme) private var colorScheme
}
