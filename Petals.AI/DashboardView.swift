//
//  ContentView.swift
//  Petals.AI
//
//  Created by Yusuf Afifi on 12/06/2025.
// Rishi Ab
//

import SwiftUI
import SwiftData
import HealthKit

struct DashboardView: View {
    @State private var healthStore = HKHealthStore()
    @State private var steps: Double = 0
    @State private var heartRate: Double = 0
    @State private var meditationMinutes: Int = 0
    @State private var isLogoZoomed = false
    @State private var showingSubscription = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.1),
                        Color.blue.opacity(0.05),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with Logo
                        VStack(spacing: 16) {
                            HStack {
                                // Logo
                                Image("icon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Petals AI")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.purple, .blue],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    
                                    Text("Your wellness journey starts here")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                        }
                        
                        // Health Stats Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Today's Health")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    fetchHealthData()
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.purple)
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                EnhancedHealthStatCard(
                                    title: "Steps",
                                    value: "\(Int(steps))",
                                    subtitle: "steps today",
                                    icon: "figure.walk",
                                    gradientColors: [.blue, .cyan],
                                    progress: min(steps / 10000, 1.0)
                                )
                                
                                EnhancedHealthStatCard(
                                    title: "Heart Rate",
                                    value: "\(Int(heartRate))",
                                    subtitle: "BPM",
                                    icon: "heart.fill",
                                    gradientColors: [.red, .pink],
                                    progress: 0.75
                                )
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Meditation Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Meditation Sessions")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("Choose your practice")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 24)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    EnhancedMeditationCard(
                                        title: "Mindful Breathing",
                                        duration: "5 min",
                                        description: "Focus on your breath",
                                        icon: "wind",
                                        gradientColors: [.mint, .green]
                                    )
                                    
                                    EnhancedMeditationCard(
                                        title: "Body Scan",
                                        duration: "10 min",
                                        description: "Relax your body",
                                        icon: "figure.stand",
                                        gradientColors: [.orange, .yellow]
                                    )
                                    
                                    EnhancedMeditationCard(
                                        title: "Stress Relief",
                                        duration: "15 min",
                                        description: "Find inner peace",
                                        icon: "leaf",
                                        gradientColors: [.purple, .indigo]
                                    )
                                    
                                    EnhancedMeditationCard(
                                        title: "Sleep Meditation",
                                        duration: "20 min",
                                        description: "Prepare for rest",
                                        icon: "moon.stars",
                                        gradientColors: [.indigo, .purple]
                                    )
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        
                        // Quick Actions
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quick Actions")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    Button(action: { showingSubscription = true }) {
                                        VStack {
                                            Image(systemName: "star.fill")
                                                .font(.title2)
                                            Text("Upgrade")
                                                .font(.caption)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(
                                            LinearGradient(
                                                colors: [.purple, .blue],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .foregroundColor(.white)
                                        .cornerRadius(15)
                                        .shadow(color: .purple.opacity(0.3), radius: 5, x: 0, y: 2)
                                    }
                                    
                                    EnhancedQuickActionButton(
                                        title: "Start Session",
                                        icon: "play.fill",
                                        color: .purple
                                    ) {
                                        // Start session action
                                    }
                                }
                                
                                HStack(spacing: 12) {
                                    EnhancedQuickActionButton(
                                        title: "View Health",
                                        icon: "heart.fill",
                                        color: .purple
                                    ) {
                                        // View health action
                                    }
                                    
                                    EnhancedQuickActionButton(
                                        title: "Meditate",
                                        icon: "moon.stars.fill",
                                        color: .purple
                                    ) {
                                        // Meditate action
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Bottom spacing
                        Spacer(minLength: 30)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            requestHealthKitAuthorization()
        }
        .sheet(isPresented: $showingSubscription) {
            SubscriptionView()
        }
    }
    
    private func requestHealthKitAuthorization() {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                fetchHealthData()
            }
        }
    }
    
    private func fetchHealthData() {
        // Fetch steps
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            let now = Date()
            let startOfDay = Calendar.current.startOfDay(for: now)
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
            
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let result = result,
                   let sum = result.sumQuantity() {
                    DispatchQueue.main.async {
                        self.steps = sum.doubleValue(for: HKUnit.count())
                    }
                }
            }
            healthStore.execute(query)
        }
        
        // Fetch heart rate
        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let sample = samples?.first as? HKQuantitySample {
                    DispatchQueue.main.async {
                        self.heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    }
                }
            }
            healthStore.execute(query)
        }
    }
}

// MARK: - Enhanced Components

struct EnhancedHealthStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let gradientColors: [Color]
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Spacer()
                
                // Progress indicator
                Circle()
                    .stroke(gradientColors.first?.opacity(0.2) ?? .gray.opacity(0.2), lineWidth: 3)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                    )
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: gradientColors.first?.opacity(0.2) ?? .gray.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

struct EnhancedMeditationCard: View {
    let title: String
    let duration: String
    let description: String
    let icon: String
    let gradientColors: [Color]
    
    var body: some View {
        Button(action: {
            // Meditation action
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Spacer()
                    
                    Text(duration)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(gradientColors.first?.opacity(0.2) ?? .gray.opacity(0.2))
                        )
                        .foregroundColor(gradientColors.first ?? .primary)
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(20)
            .frame(width: 180, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: gradientColors.first?.opacity(0.2) ?? .gray.opacity(0.2), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: color.opacity(0.1), radius: 6, x: 0, y: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DashboardView()
}
