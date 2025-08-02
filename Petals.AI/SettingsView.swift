import SwiftUI
import HealthKit

struct SettingsView: View {
    @Binding var healthKitAuthorized: Bool
    let onPermissionsGranted: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    
    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled = true
    @AppStorage("dailyReminderTime") private var dailyReminderTime: Date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    
    @State private var notificationsEnabled = true
    @State private var selectedTheme = 0 // 0: System, 1: Light, 2: Dark

    var body: some View {
        NavigationView {
            ZStack {
                // Adaptive background
                (colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground))
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
                                
                                Image(systemName: "gear.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.purple, .blue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            Text("Settings")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        
                        // Notifications
                        SettingsSection(title: "Notifications") {
                            Toggle(isOn: $dailyReminderEnabled) {
                                Text("Daily Reminder")
                            }
                            .onChange(of: dailyReminderEnabled) { _, newValue in
                                if newValue {
                                    NotificationManager.shared.scheduleDailyCheckIn(at: dailyReminderTime)
                                } else {
                                    NotificationManager.shared.disableDailyCheckIn()
                                }
                            }
                            
                            if dailyReminderEnabled {
                                DatePicker("Time", selection: $dailyReminderTime, displayedComponents: .hourAndMinute)
                                    .onChange(of: dailyReminderTime) { _, newValue in
                                        NotificationManager.shared.scheduleDailyCheckIn(at: newValue)
                                    }
                            }
                        }
                        
                        // Permissions
                        SettingsSection(title: "Permissions") {
                            PermissionRow(
                                title: "Health Data",
                                description: "Steps, heart rate, sleep, etc.",
                                icon: "heart.fill",
                                color: .red,
                                isGranted: healthKitAuthorized
                            ) {
                                requestHealthKitPermission()
                            }
                            
                            PermissionRow(
                                title: "Screen Time",
                                description: "App usage insights",
                                icon: "iphone",
                                color: .orange,
                                isGranted: screenTimeManager.isAuthorized
                            ) {
                                requestScreenTimePermission()
                            }
                        }
                        
                        // About
                        SettingsSection(title: "About") {
                            NavigationLink(destination: AboutView()) {
                                SettingsRow(title: "About Petals AI", icon: "info.circle.fill")
                            }
                            NavigationLink(destination: HelpView()) {
                                SettingsRow(title: "Help & Support", icon: "questionmark.circle.fill")
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            screenTimeManager.checkAuthorizationStatus()
        }
    }
    
    private func requestHealthKitPermission() {
        Task {
            HealthDataManager.shared.requestHealthKitAuthorization()
            await MainActor.run {
                healthKitAuthorized = true
            }
        }
    }
    
    private func requestScreenTimePermission() {
        Task {
            await screenTimeManager.requestAuthorization()
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.leading, 4)
            
            VStack(spacing: 12) {
                content
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.purple)
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct AboutView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground))
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("About Petals AI")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Petals is a private, on-device AI wellness app for iPhone. It uses Apple’s Neural Engine for fast and secure AI experiences — no internet needed.")
                        .foregroundColor(.primary)

                    Text("Features include:")
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("A context-aware AI chatbot", systemImage: "message.fill")
                        Label("Personalized nutrition and workout plans", systemImage: "leaf.fill")
                        Label("Meditation and mindfulness support", systemImage: "brain.head.profile")
                        Label("Journaling for reflection and focus", systemImage: "book.closed.fill")
                    }
                    .foregroundColor(.primary)
                    .padding(.leading, 8)

                    Text("Everything runs on your device, and your health data stays private. Petals doesn’t send any data to the cloud.")
                        .foregroundColor(.primary)

                    Text("If a response seems limited, it may be due to built-in safety guardrails. Try rephrasing your question for better results.")
                        .foregroundColor(.primary)
                    
                    Text("If an AI response fails, ensure the device is not on low power mode and try again.")
                        .foregroundColor(.primary)

                    Text("For richer voice output, enable enhanced voices in Settings > Accessibility > Voice Over > Speech.")
                        .foregroundColor(.primary)

                    Divider().background(Color.secondary)

                    Text("🌐 Connect with us")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Website: petalsapp.ai\nInstagram, TikTok, X: @petals.ai")
                        .foregroundColor(.primary)

                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground))
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Help & Support")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Need help using Petals? Here’s a quick guide:")
                        .foregroundColor(.primary)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("• **Permissions**: Enable Health and Screen Time for personalized insights.")
                        Text("• **Daily Reminders**: Manage notifications and reminder times in Settings.")
                        Text("• **Refining Questions**: If a response seems off, try rewording it. Guardrails may restrict some outputs.")
                        Text("• **Voice Output**: For improved spoken responses, enable enhanced voices (Settings > Accessibility >  Voice Over > Speech .")
                        Text("• **Privacy**: All AI runs locally. Your data is never uploaded.")
                        Text("• **App issues?** Restart the app. For updates, follow us on social media.")
                    }
                    .foregroundColor(.primary)

                    Divider().background(Color.secondary)
                    
                    Text("🌐 Connect with us")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Website: petalsapp.ai\nInstagram, TikTok, X: @petals.ai")
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PermissionRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.2).clipShape(Circle()))
            
            VStack(alignment: .leading) {
                Text(title).font(.headline)
                Text(description).font(.caption).foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            } else {
                Button("Grant", action: action)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(color.cornerRadius(12))
            }
        }
    }
}

