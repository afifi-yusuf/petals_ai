import SwiftUI
import DeviceActivity
import SwiftData
import HealthKit
import FamilyControls

extension DeviceActivityReport.Context {
    // If your app initializes a DeviceActivityReport with this context, then the system will use
    // your extension's corresponding DeviceActivityReportScene to render the contents of the
    // report.
    static let totalActivity = Self("Total Activity")
}

struct DashboardView: View {
    @State private var healthStore = HKHealthStore()
    @State private var stepsStatus: HealthDataManager.HealthDataStatus?
    @State private var heartRateStatus: HealthDataManager.HealthDataStatus?
    @State private var sleepStatus: HealthDataManager.HealthDataStatus?
    @State private var activeEnergyStatus: HealthDataManager.HealthDataStatus?
    @State private var isLogoZoomed = false
    @State private var showingMeditation = false
    @State private var showingJournal = false
    @State private var showingSettings = false
    @State private var healthKitAuthorized = false
    
    @State private var showingWorkoutPlan = false
    @State private var showingNutritionPlan = false
    @State private var showingDigitalWellness = false
    @State private var showHealthDetails = false
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @StateObject private var moodManager = MoodManager.shared
    @Environment(\.modelContext) var modelContext
    @State private var streak: Int = 0
    
    
    
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic background with subtle animation
                AnimatedBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Compact Header
                        CompactHeader(streak: moodManager.currentStreak, showingSettings: $showingSettings)
                        
                        // Permissions Banner (if needed)
                        
                        
                        // Hero Wellness Features - The main attraction
                        WellnessFeaturesSection(
                            showingMeditation: $showingMeditation,
                            showingJournal: $showingJournal,
                            showingWorkoutPlan: $showingWorkoutPlan,
                            showingNutritionPlan: $showingNutritionPlan
                        )
                        
                        // Quick Health Insights - Minimized but present
                        QuickHealthInsights(
                            stepsStatus: stepsStatus,
                            heartRateStatus: heartRateStatus,
                            sleepStatus: sleepStatus,
                            activeEnergyStatus: activeEnergyStatus,
                            showHealthDetails: $showHealthDetails,
                            onRefresh: {
                                Task { await fetchHealthData() }
                            }
                        )
                        
                        ScreenTimeSummaryCard(screenTimeManager: screenTimeManager) {
                            showingDigitalWellness = true   // opens your BlockAppPicker
                        }
                    
                        // Today's Mood - Only if has data
                        if let mood = moodManager.todaysMood {
                            TodaysMoodCard(mood: mood)
                        }
                        
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
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
        .fullScreenCover(isPresented: $showingNutritionPlan) {
            NutritionPlanView()
        }
        .fullScreenCover(isPresented: $showingDigitalWellness) {
            BlockAppPicker()
        }
        .sheet(isPresented: $showingSettings) {
                SettingsView(
                    healthKitAuthorized: $healthKitAuthorized,
                    onPermissionsGranted: {
                        Task {
                            await fetchHealthData()
                        }
                    }
                )
            }
        .sheet(isPresented: $showHealthDetails) {
            DetailedHealthView(
                stepsStatus: stepsStatus,
                heartRateStatus: heartRateStatus,
                sleepStatus: sleepStatus,
                activeEnergyStatus: activeEnergyStatus,
                onRefresh: {
                    Task { await fetchHealthData() }
                }
            )
        }
    }

    
    
    
    
    private func fetchHealthData() async {
        stepsStatus = await HealthDataManager.shared.getStepsStatus()
        heartRateStatus = await HealthDataManager.shared.getHeartRateStatus()
        sleepStatus = await HealthDataManager.shared.getSleepStatus()
        activeEnergyStatus = await HealthDataManager.shared.getActiveEnergyStatus()
    }
}

private extension DateInterval {
    static var today: DateInterval {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end   = cal.date(byAdding: .day, value: 1, to: start)!
        return DateInterval(start: start, end: end)
    }
}
struct ScreenTimeSummaryCard: View {
    @ObservedObject var screenTimeManager: ScreenTimeManager
    var onManageTapped: () -> Void

    @State private var filter = DeviceActivityFilter(segment: .daily(during: .today))

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: "iphone")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Digital Detox")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button {
                    onManageTapped()
                } label: {
                    HStack(spacing: 6) {
                        Text("Manage")
                            .fontWeight(.medium)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.orange.opacity(0.1))
                    )
                }
                .font(.caption)
                .foregroundColor(.orange)
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.orange.opacity(0.3), .pink.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
// MARK: - Animated Background
struct AnimatedBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.05),
                    Color.blue.opacity(0.03),
                    Color.mint.opacity(0.02),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Floating orbs
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.purple.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .offset(
                        x: animate ? CGFloat.random(in: -50...50) : CGFloat.random(in: -30...30),
                        y: animate ? CGFloat.random(in: -100...100) : CGFloat.random(in: -50...50)
                    )
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 3...5))
                            .repeatForever(autoreverses: true),
                        value: animate
                    )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            animate = true
        }
    }
}

// MARK: - Compact Header
struct CompactHeader: View {
    let streak: Int
    @Binding var showingSettings: Bool
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image("icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .purple.opacity(0.3), radius: 3, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Petals AI")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    HStack(spacing: 8) {
                        Text("\(Image(systemName: "star.fill")) \(streak) day streak")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                showingSettings = true
            }) {
                Image(systemName: "gear")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.primary.opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Hero Wellness Features Section
struct WellnessFeaturesSection: View {
    @Binding var showingMeditation: Bool
    @Binding var showingJournal: Bool
    @Binding var showingWorkoutPlan: Bool
    @Binding var showingNutritionPlan: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Wellness Journey")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.leading, 4)
            
            // Primary Feature Cards (2x2 grid)
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                
                HeroFeatureCard(
                    title: "Meditation",
                    subtitle: "Find your center",
                    icon: "brain.head.profile",
                    gradientColors: [.purple, .indigo],
                    action: { showingMeditation = true }
                )
                
                HeroFeatureCard(
                    title: "Journal",
                    subtitle: "Express yourself",
                    icon: "book.fill",
                    gradientColors: [.blue, .cyan],
                    action: { showingJournal = true }
                )
                
                HeroFeatureCard(
                    title: "Workout",
                    subtitle: "Move your body",
                    icon: "figure.strengthtraining.traditional",
                    gradientColors: [.red, .orange],
                    action: { showingWorkoutPlan = true }
                )
                
                HeroFeatureCard(
                    title: "Nutrition",
                    subtitle: "Fuel properly",
                    icon: "leaf.fill",
                    gradientColors: [.green, .mint],
                    action: { showingNutritionPlan = true }
                )
            }
        }
    }
}

// MARK: - Hero Feature Card
struct HeroFeatureCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradientColors: [Color]
    let action: () -> Void
    
    @State private var isPressed = false
    @GestureState private var isLongPressing: Bool = false
    @State private var isLongPressActive: Bool = false
    
    @State private var longPressProgress: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                // Icon with background and circular progress overlay
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradientColors.map { $0.opacity(0.2) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    if isLongPressActive {
                        Circle()
                            .trim(from: 0, to: longPressProgress)
                            .stroke(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 68, height: 68)
                            .accessibilityLabel(Text("Long press progress"))
                            .accessibilityValue(Text("\(Int(longPressProgress * 100)) percent"))
                    }
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Action indicator
                HStack(spacing: 4) {
                    Text("Start")
                        .font(.caption2)
                        .fontWeight(.semibold)
                    
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                .foregroundStyle(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            .frame(width: 100, height:150)
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: gradientColors.map { $0.opacity(0.3) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: gradientColors.first?.opacity(0.2) ?? .clear,
                        radius: isPressed ? 8 : 12,
                        x: 0,
                        y: isPressed ? 4 : 8
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .accessibilityAddTraits(.isButton)
        }
        .gesture(
            LongPressGesture(minimumDuration: 2.0)
                .updating($isLongPressing) { currentState, state, _ in
                    state = currentState
                }
                .onChanged { _ in
                    // handled by .onChange(of: isLongPressing)
                }
                .onEnded { finished in
                    if finished {
                        action()
                    }
                    resetLongPressState()
                }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isLongPressActive {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    if !isLongPressActive {
                        isPressed = false
                    }
                    if !isLongPressActive {
                        resetLongPressState()
                    }
                }
        )
        .onChange(of: isLongPressing) { oldValue, newValue in
            if newValue {
                startLongPressAnimation()
            } else {
                resetLongPressState()
            }
        }
    }
    
    private func startLongPressAnimation() {
        isLongPressActive = true
        longPressProgress = 0
        withAnimation(.linear(duration: 2.0)) {
            longPressProgress = 1.0
        }
    }
    
    private func resetLongPressState() {
        isLongPressActive = false
        isPressed = false
        longPressProgress = 0.0
    }
}

// MARK: - Quick Health Insights (Minimized)
struct QuickHealthInsights: View {
    let stepsStatus: HealthDataManager.HealthDataStatus?
    let heartRateStatus: HealthDataManager.HealthDataStatus?
    let sleepStatus: HealthDataManager.HealthDataStatus?
    let activeEnergyStatus: HealthDataManager.HealthDataStatus?
    @Binding var showHealthDetails: Bool
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Health Snapshot")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("View All") {
                    showHealthDetails = true
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.purple)
            }
            
            HStack(spacing: 12) {
                CompactHealthItem(
                    icon: "figure.walk",
                    value: stepsStatus?.hasData == true ? "\(Int(stepsStatus!.value))" : "—",
                    color: .blue
                )
                
                CompactHealthItem(
                    icon: "heart.fill",
                    value: heartRateStatus?.hasData == true ? "\(Int(heartRateStatus!.value))" : "—",
                    color: .red
                )
                
                CompactHealthItem(
                    icon: "bed.double.fill",
                    value: sleepStatus?.hasData == true ? "\(String(format: "%.1f", sleepStatus!.value))h" : "—",
                    color: .indigo
                )
                
                CompactHealthItem(
                    icon: "flame.fill",
                    value: activeEnergyStatus?.hasData == true ? "\(String(format: "%.1f", activeEnergyStatus!.value))cal" : "—",
                    color: .orange
                )
                
                Spacer()
                
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.secondary.opacity(0.1))
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Compact Health Item
struct CompactHealthItem: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .frame(width: 44)
    }
}

// MARK: - Todays Mood Card
struct TodaysMoodCard: View {
    let mood: MoodType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: mood.icon)
                    .font(.title2)
                    .foregroundColor(mood.color)
                
                Text("Today's Mood: \(mood.title)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text(mood.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(mood.color.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: mood.color.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Screen Time Stat Card
struct ScreenTimeStatCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradientColors: [Color]

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
            }
            
            DeviceActivityReport(.totalActivity)
                .frame(height: 50)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: gradientColors.first?.opacity(0.2) ?? .gray.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .frame(width: 170, height: 170)
    }
}

// MARK: - Detailed Health View
struct DetailedHealthView: View {
    let stepsStatus: HealthDataManager.HealthDataStatus?
    let heartRateStatus: HealthDataManager.HealthDataStatus?
    let sleepStatus: HealthDataManager.HealthDataStatus?
    let activeEnergyStatus: HealthDataManager.HealthDataStatus?
    let onRefresh: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
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
                    
                    ScreenTimeStatCard(
                        title: "Screen Time",
                        subtitle: "Total screen time today",
                        icon: "iphone.gen1",
                        gradientColors: [.blue, .purple]
                    )
                }
                .padding()
            }
            .navigationTitle("Health Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
}

// MARK: - Custom Button Style for Press Effect
extension View {
    func onPressGesture(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}

// MARK: - Keep existing components
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
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(strokeColor, lineWidth: 1)
                    )
                    .shadow(color: colorScheme == .dark ? .clear : .orange.opacity(0.1), radius: 6, x: 0, y: 3)
            )
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
//        .onAppear {
//            screenTimeManager.checkAuthorizationStatus()
//        }
    }
    
    private func requestHealthKitPermission() {
        guard !isRequestingHealthKit else { return }
        isRequestingHealthKit = true
        Task {
            await MainActor.run {
                HealthDataManager.shared.requestHealthKitAuthorization()
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                healthKitAuthorized = true
                isRequestingHealthKit = false
            }
        }
    }
    
  private func requestScreenTimePermission() {
      guard !isRequestingScreenTime else { return }
       isRequestingScreenTime = true

       Task {
            await screenTimeManager.requestAuthorizationIfNeeded()
            await MainActor.run {
              isRequestingScreenTime = false
         }
     }
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
        .frame(width: 170, height: 170)
    }
}

// MARK: - Digital Stat Card
struct DigitalStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let trend: TrendDirection
    
    enum TrendDirection {
        case up, down, neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .neutral: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .red
            case .down: return .green
            case .neutral: return .secondary
            }
        }
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                Image(systemName: trend.icon)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(trend.color)
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(
            (colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white.opacity(0.95))
                .cornerRadius(16)
                .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - App Usage Row
struct AppUsageRow: View {
    let appName: String
    let time: String
    let percentage: Double
    let color: Color
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(appName)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(time)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            (colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white.opacity(0.95))
                .cornerRadius(12)
        )
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    let insight: String
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.orange)
                .font(.caption)
            
            Text(insight)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(12)
        .background(
            (colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white.opacity(0.95))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.1), lineWidth: 1)
                )
        )
    }
}


#Preview {
    DashboardView()
}

