import SwiftUI
import SwiftData
import HealthKit
import FamilyControls

struct DashboardView: View {
    @State private var healthStore = HKHealthStore()
    @State private var stepsStatus: HealthDataManager.HealthDataStatus?
    @State private var heartRateStatus: HealthDataManager.HealthDataStatus?
    @State private var mindfulnessStatus: HealthDataManager.HealthDataStatus?
    @State private var sleepStatus: HealthDataManager.HealthDataStatus?
    @State private var activeEnergyStatus: HealthDataManager.HealthDataStatus?
    @State private var screenTimeStatus: HealthDataManager.HealthDataStatus?
    @State private var isLogoZoomed = false
    @State private var showingSubscription = false
    @State private var showingMeditation = false
    @State private var showingJournal = false
    @State private var showingPermissions = false
    @State private var healthKitAuthorized = false
    @State private var hasInitialLoad = false
    @State private var showingWorkoutPlan = false
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    
    var needsPermissions: Bool {
        !healthKitAuthorized || !screenTimeManager.isAuthorized
    }
    
    // Track if permissions have ever been granted
    @State private var permissionsCompleted = false

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
                                
                                // Permissions button (show only if not completed)
                                if needsPermissions && !permissionsCompleted {
                                    Button(action: {
                                        showingPermissions = true
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "lock.shield")
                                                .font(.caption)
                                            Text("Permissions")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.orange.opacity(0.15))
                                        .foregroundColor(.orange)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                }
                                
                                #if DEBUG
                                Button(action: {
                                    Task {
                                        await HealthDataManager.shared.populateSampleData()
                                        await fetchHealthData()
                                    }
                                }) {
                                    Text("Debug")
                                        .font(.system(size: 10, weight: .medium))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.red.opacity(0.1))
                                        .foregroundColor(.red)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                #endif
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                        }
                        
                        // Permissions Banner (show only if not completed)
                        if needsPermissions && !permissionsCompleted {
                            PermissionsBanner {
                                showingPermissions = true
                            }
                        }
                        
                        // Health Stats Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Today's Wellness")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    Task {
                                        await fetchHealthData()
                                    }
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
                                    value: stepsStatus?.message ?? "Loading...",
                                    subtitle: stepsStatus?.hasData == true ? "steps today" : (stepsStatus?.suggestion ?? ""),
                                    icon: "figure.walk",
                                    gradientColors: [.blue, .cyan],
                                    progress: stepsStatus?.hasData == true ? min(stepsStatus!.value / 10000, 1.0) : 0.0,
                                    hasData: stepsStatus?.hasData ?? false
                                )
                                
                                EnhancedHealthStatCard(
                                    title: "Heart Rate",
                                    value: heartRateStatus?.message ?? "Loading...",
                                    subtitle: heartRateStatus?.hasData == true ? "BPM" : (heartRateStatus?.suggestion ?? ""),
                                    icon: "heart.fill",
                                    gradientColors: [.red, .pink],
                                    progress: heartRateStatus?.hasData == true ? 0.75 : 0.0,
                                    hasData: heartRateStatus?.hasData ?? false
                                )
                                
                                EnhancedHealthStatCard(
                                    title: "Mindfulness",
                                    value: mindfulnessStatus?.message ?? "Loading...",
                                    subtitle: mindfulnessStatus?.hasData == true ? "today" : (mindfulnessStatus?.suggestion ?? ""),
                                    icon: "brain.head.profile",
                                    gradientColors: [.mint, .green],
                                    progress: mindfulnessStatus?.hasData == true ? min(mindfulnessStatus!.value / 30, 1.0) : 0.0,
                                    hasData: mindfulnessStatus?.hasData ?? false
                                )
                                
                                EnhancedHealthStatCard(
                                    title: "Screen Time",
                                    value: screenTimeStatus?.message ?? "Loading...",
                                    subtitle: screenTimeStatus?.hasData == true ? "today" : (screenTimeStatus?.suggestion ?? ""),
                                    icon: "iphone",
                                    gradientColors: [.orange, .yellow],
                                    progress: screenTimeStatus?.hasData == true ? min(screenTimeStatus!.value / (8 * 3600), 1.0) : 0.0,
                                    hasData: screenTimeStatus?.hasData ?? false
                                )
                                
                                EnhancedHealthStatCard(
                                    title: "Sleep",
                                    value: sleepStatus?.message ?? "Loading...",
                                    subtitle: sleepStatus?.hasData == true ? "last night" : (sleepStatus?.suggestion ?? ""),
                                    icon: "bed.double.fill",
                                    gradientColors: [.indigo, .purple],
                                    progress: sleepStatus?.hasData == true ? min(sleepStatus!.value / 8, 1.0) : 0.0,
                                    hasData: sleepStatus?.hasData ?? false
                                )
                                
                                EnhancedHealthStatCard(
                                    title: "Energy",
                                    value: activeEnergyStatus?.message ?? "Loading...",
                                    subtitle: activeEnergyStatus?.hasData == true ? "kcal" : (activeEnergyStatus?.suggestion ?? ""),
                                    icon: "flame.fill",
                                    gradientColors: [.red, .orange],
                                    progress: activeEnergyStatus?.hasData == true ? min(activeEnergyStatus!.value / 500, 1.0) : 0.0,
                                    hasData: activeEnergyStatus?.hasData ?? false
                                )
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Digital Wellness Insights
                        if screenTimeManager.isAuthorized && screenTimeStatus?.hasData == true {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Digital Wellness")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 24)
                                
                                VStack(spacing: 8) {
                                    ForEach(screenTimeManager.getDigitalWellnessInsights(), id: \.self) { insight in
                                        HStack {
                                            Image(systemName: "lightbulb.fill")
                                                .foregroundColor(.orange)
                                                .font(.caption)
                                            Text(insight)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 24)
                                    }
                                }
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .orange.opacity(0.1), radius: 8, x: 0, y: 4)
                                )
                                .padding(.horizontal, 24)
                            }
                        }
                        
                        // Wellness Features
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Wellness Features")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 24)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                EnhancedQuickActionButton(
                                    title: "Start Meditation",
                                    icon: "brain.head.profile",
                                    color: .purple
                                ) {
                                    showingMeditation = true
                                }
                                
                                EnhancedQuickActionButton(
                                    title: "Journal Entry",
                                    icon: "book.fill",
                                    color: .blue
                                ) {
                                    showingJournal = true
                                }
                                
                                EnhancedQuickActionButton(
                                    title: "Chat with AI",
                                    icon: "message.fill",
                                    color: .green
                                ) {
                                    // Chat action
                                }
                                
                                EnhancedQuickActionButton(
                                    title: "Workout Plan",
                                    icon: "figure.strengthtraining.traditional",
                                    color: .red
                                ) {
                                    showingWorkoutPlan = true
                                }
                                
                                EnhancedQuickActionButton(
                                    title: "Subscription",
                                    icon: "crown.fill",
                                    color: .orange
                                ) {
                                    showingSubscription = true
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
            if !hasInitialLoad {
                checkInitialPermissions()
                hasInitialLoad = true
            }
        }
        .fullScreenCover(isPresented: $showingSubscription) {
            SubscriptionView()
        }
        .fullScreenCover(isPresented: $showingMeditation) {
            MeditationView()
        }
        .fullScreenCover(isPresented: $showingJournal) {
            JournalView()
        }
        .fullScreenCover(isPresented: $showingWorkoutPlan) {
            WorkoutPlanView()
        }
        .sheet(isPresented: $showingPermissions, onDismiss: {
            // Always re-check after sheet closes
            checkInitialPermissions()
            if !needsPermissions {
                permissionsCompleted = true
            }
        }) {
            PermissionsView(
                healthKitAuthorized: $healthKitAuthorized,
                onPermissionsGranted: {
                    Task {
                        await fetchHealthData()
                        // If permissions are now granted, mark as completed
                        if !needsPermissions {
                            permissionsCompleted = true
                        }
                    }
                }
            )
        }
    }
    
    private func checkInitialPermissions() {
        // Check if HealthKit is available and authorized
        if HKHealthStore.isHealthDataAvailable() {
            let healthTypes: Set<HKObjectType> = [
                HKQuantityType.quantityType(forIdentifier: .stepCount)!,
                HKQuantityType.quantityType(forIdentifier: .heartRate)!,
                HKCategoryType.categoryType(forIdentifier: .mindfulSession)!,
                HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!,
                HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
            ]
            
            healthKitAuthorized = healthTypes.allSatisfy { type in
                healthStore.authorizationStatus(for: type) == .sharingAuthorized
            }
        }
        
        // Fetch initial data
        Task {
            await fetchHealthData()
        }
    }
    
    private func fetchHealthData() async {
        stepsStatus = await HealthDataManager.shared.getStepsStatus()
        heartRateStatus = await HealthDataManager.shared.getHeartRateStatus()
        mindfulnessStatus = await HealthDataManager.shared.getMindfulnessStatus()
        sleepStatus = await HealthDataManager.shared.getSleepStatus()
        activeEnergyStatus = await HealthDataManager.shared.getActiveEnergyStatus()
        screenTimeStatus = await screenTimeManager.getScreenTimeStatus()
    }
}

// MARK: - Permissions Banner (Dark Mode Fixed)
struct PermissionsBanner: View {
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var backgroundColor: Color {
        colorScheme == .dark ?
            Color.orange.opacity(0.15) :
            Color.orange.opacity(0.1)
    }
    
    var strokeColor: Color {
        colorScheme == .dark ?
            Color.orange.opacity(0.4) :
            Color.orange.opacity(0.3)
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Setup Required")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Grant permissions to unlock your wellness insights")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.orange)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(strokeColor, lineWidth: 1)
                    )
                    .shadow(color: colorScheme == .dark ? .clear : .orange.opacity(0.1), radius: 6, x: 0, y: 3)
            )
            .padding(.horizontal, 24)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Permissions View (Dark Mode Fixed)
struct PermissionsView: View {
    @Binding var healthKitAuthorized: Bool
    let onPermissionsGranted: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @State private var isRequestingHealthKit = false
    @State private var isRequestingScreenTime = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Adaptive background
                (colorScheme == .dark ? Color.black : Color.white)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple.opacity(0.1), .blue.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "heart.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.purple, .blue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            Text("Enable Health Data")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                            
                            Text("Grant permissions to get personalized wellness insights and track your progress")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(.top, 40)
                        
                        VStack(spacing: 20) {
                            // HealthKit Permission
                            PermissionCard(
                                title: "Health Data",
                                description: "Steps, heart rate, sleep, and exercise data",
                                icon: "heart.fill",
                                color: .red,
                                isGranted: healthKitAuthorized,
                                isRequesting: isRequestingHealthKit
                            ) {
                                requestHealthKitPermission()
                            }
                            
                            // Screen Time Permission
                            PermissionCard(
                                title: "Screen Time",
                                description: "App usage and digital wellness insights",
                                icon: "iphone",
                                color: .orange,
                                isGranted: screenTimeManager.isAuthorized,
                                isRequesting: isRequestingScreenTime
                            ) {
                                requestScreenTimePermission()
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer()
                        
                        // Continue Button
                        Button(action: {
                            onPermissionsGranted()
                            dismiss()
                        }) {
                            Text("Continue")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Permissions")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            // No need to check HealthKit status for green tick anymore
            screenTimeManager.checkAuthorizationStatus()
        }
    }
    
    private func requestHealthKitPermission() {
        guard !isRequestingHealthKit else { return }
        isRequestingHealthKit = true
        Task {
            await MainActor.run {
                HealthDataManager.shared.requestHealthKitAuthorization()
            }
            // Wait a moment for the authorization to complete
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            await MainActor.run {
                healthKitAuthorized = true // Always set to true after grant
                isRequestingHealthKit = false
            }
        }
    }
    
    private func requestScreenTimePermission() {
        guard !isRequestingScreenTime else { return }
        isRequestingScreenTime = true
        
        Task {
            await screenTimeManager.requestAuthorization()
            await MainActor.run {
                isRequestingScreenTime = false
            }
        }
    }
    
    private func checkHealthKitStatus() {
        let healthStore = HKHealthStore()
        let healthTypes: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKCategoryType.categoryType(forIdentifier: .mindfulSession)!,
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        for type in healthTypes {
            print("[HealthKit] \(type.identifier): \(healthStore.authorizationStatus(for: type).rawValue)")
        }
        healthKitAuthorized = healthTypes.allSatisfy { type in
            healthStore.authorizationStatus(for: type) == .sharingAuthorized
        }
        print("[HealthKit] healthKitAuthorized: \(healthKitAuthorized)")
    }
}

// MARK: - Permission Card (Dark Mode Fixed)
struct PermissionCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isGranted: Bool
    let isRequesting: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var backgroundColor: Color {
        colorScheme == .dark ?
            Color.gray.opacity(0.15) :
            Color.white.opacity(0.8)
    }
    
    var strokeColor: Color {
        if isGranted {
            return color.opacity(0.6)
        } else {
            return colorScheme == .dark ?
                Color.gray.opacity(0.3) :
                Color.gray.opacity(0.2)
        }
    }
    
    var iconBackgroundColor: Color {
        if isGranted {
            return color.opacity(0.2)
        } else {
            return colorScheme == .dark ?
                Color.gray.opacity(0.2) :
                Color.gray.opacity(0.15)
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isGranted ? color : (colorScheme == .dark ? .white.opacity(0.7) : .gray))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(iconBackgroundColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            if isRequesting {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.primary)
            } else if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            } else {
                Button("Grant", action: action)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(strokeColor, lineWidth: 1)
                )
                .shadow(color: colorScheme == .dark ? .clear : .gray.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Enhanced Health Stat Card
struct EnhancedHealthStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let gradientColors: [Color]
    let progress: Double
    let hasData: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: hasData ? gradientColors : [.gray, .gray.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Spacer()
                
                // Progress indicator
                Circle()
                    .stroke(hasData ? (gradientColors.first?.opacity(0.2) ?? .gray.opacity(0.2)) : .gray.opacity(0.1), lineWidth: 3)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                LinearGradient(
                                    colors: hasData ? gradientColors : [.gray, .gray.opacity(0.5)],
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
                .foregroundColor(hasData ? .primary : .secondary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(hasData ? .secondary : .orange)
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: hasData ? (gradientColors.first?.opacity(0.2) ?? .gray.opacity(0.2)) : .gray.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Enhanced Meditation Card
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

// MARK: - Enhanced Quick Action Button
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
