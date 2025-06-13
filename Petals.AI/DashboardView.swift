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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome to Petals.AI")
                            .font(.largeTitle)
                            .bold()
                        Text("Your health & meditation companion")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Health Stats Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        HealthStatCard(
                            title: "Steps",
                            value: "\(Int(steps))",
                            icon: "figure.walk",
                            color: .blue
                        )
                        
                        HealthStatCard(
                            title: "Heart Rate",
                            value: "\(Int(heartRate)) BPM",
                            icon: "heart.fill",
                            color: .red
                        )
                    }
                    .padding(.horizontal)
                    
                    // Meditation Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Meditation")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                MeditationCard(
                                    title: "Mindful Breathing",
                                    duration: "5 min",
                                    icon: "wind"
                                )
                                
                                MeditationCard(
                                    title: "Body Scan",
                                    duration: "10 min",
                                    icon: "figure.stand"
                                )
                                
                                MeditationCard(
                                    title: "Stress Relief",
                                    duration: "15 min",
                                    icon: "leaf"
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Actions")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        HStack(spacing: 16) {
                            QuickActionButton(
                                title: "Start Meditation",
                                icon: "play.circle.fill",
                                color: .purple
                            )
                            
                            QuickActionButton(
                                title: "View Health",
                                icon: "heart.text.square.fill",
                                color: .green
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Settings action
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .onAppear {
            requestHealthKitAuthorization()
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

struct HealthStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .bold()
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}

struct MeditationCard: View {
    let title: String
    let duration: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.purple)
            
            Text(title)
                .font(.headline)
            
            Text(duration)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 160)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {
            // Action
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                Text(title)
                    .font(.subheadline)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 5)
        }
    }
}

#Preview {
    DashboardView()
}
