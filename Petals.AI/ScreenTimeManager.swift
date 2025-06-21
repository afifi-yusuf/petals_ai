import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings

@MainActor
class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()
    
    @Published var isAuthorized = false
    @Published var todaysScreenTime: TimeInterval = 0
    @Published var weeklyScreenTime: TimeInterval = 0
    @Published var mostUsedApps: [AppUsage] = []
    @Published var showingAuthorizationRequest = false
    
    private let center = AuthorizationCenter.shared
    private let store = ManagedSettingsStore()
    
    struct AppUsage {
        let bundleIdentifier: String
        let name: String
        let usageTime: TimeInterval
        let category: String
    }
    
    private init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        Task {
            let status = center.authorizationStatus
            await MainActor.run {
                self.isAuthorized = status == .approved
            }
        }
    }
    
    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
            await MainActor.run {
                self.isAuthorized = true
                self.showingAuthorizationRequest = false
            }
        } catch {
            print("Failed to request Family Controls authorization: \(error)")
            await MainActor.run {
                self.showingAuthorizationRequest = false
            }
        }
    }
    
    func getScreenTimeStatus() async -> HealthDataManager.HealthDataStatus {
        guard isAuthorized else {
            return HealthDataManager.HealthDataStatus(
                value: 0,
                hasData: false,
                message: "No access",
                suggestion: "Grant Screen Time permissions to track digital wellness"
            )
        }
        
        do {
            let screenTime = try await getTodaysScreenTime()
            if screenTime > 0 {
                let hours = screenTime / 3600
                let minutes = Int((screenTime.truncatingRemainder(dividingBy: 3600)) / 60)
                
                let message: String
                if hours >= 1 {
                    message = String(format: "%.1f h", hours)
                } else {
                    message = "\(minutes) min"
                }
                
                return HealthDataManager.HealthDataStatus(
                    value: screenTime,
                    hasData: true,
                    message: message,
                    suggestion: nil
                )
            } else {
                return HealthDataManager.HealthDataStatus(
                    value: 0,
                    hasData: false,
                    message: "No data",
                    suggestion: "Screen Time data not available yet"
                )
            }
        } catch {
            return HealthDataManager.HealthDataStatus(
                value: 0,
                hasData: false,
                message: "No data",
                suggestion: "Check Screen Time permissions"
            )
        }
    }
    
    func getTodaysScreenTime() async throws -> TimeInterval {
        // Note: This is a simplified implementation
        // In a real app, you would use DeviceActivity framework to get actual data
        // For now, we'll return a placeholder value
        
        // Simulate some screen time data
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let timeSinceStartOfDay = now.timeIntervalSince(startOfDay)
        
        // Simulate 4-8 hours of screen time based on time of day
        let hourOfDay = calendar.component(.hour, from: now)
        let baseScreenTime: TimeInterval
        
        switch hourOfDay {
        case 0..<6:
            baseScreenTime = 0 // Night time
        case 6..<12:
            baseScreenTime = 2 * 3600 // Morning
        case 12..<18:
            baseScreenTime = 4 * 3600 // Afternoon
        case 18..<24:
            baseScreenTime = 6 * 3600 // Evening
        default:
            baseScreenTime = 4 * 3600
        }
        
        // Add some randomness and time-based progression
        let progress = timeSinceStartOfDay / (24 * 3600)
        let screenTime = baseScreenTime * progress + Double.random(in: 0...3600)
        
        return min(screenTime, 8 * 3600) // Cap at 8 hours
    }
    
    func getWeeklyScreenTime() async throws -> TimeInterval {
        // Simulate weekly screen time (average 5 hours per day)
        return 5 * 7 * 3600 + Double.random(in: -3600...3600)
    }
    
    func getMostUsedApps() async -> [AppUsage] {
        // Simulate most used apps data
        let apps = [
            AppUsage(bundleIdentifier: "com.apple.Safari", name: "Safari", usageTime: 2.5 * 3600, category: "Social"),
            AppUsage(bundleIdentifier: "com.apple.Messages", name: "Messages", usageTime: 1.8 * 3600, category: "Communication"),
            AppUsage(bundleIdentifier: "com.instagram.ios", name: "Instagram", usageTime: 1.5 * 3600, category: "Social"),
            AppUsage(bundleIdentifier: "com.apple.Mail", name: "Mail", usageTime: 1.2 * 3600, category: "Productivity"),
            AppUsage(bundleIdentifier: "com.apple.Music", name: "Music", usageTime: 0.8 * 3600, category: "Entertainment")
        ]
        
        return apps.sorted { $0.usageTime > $1.usageTime }
    }
    
    func getDigitalWellnessInsights() -> [String] {
        var insights: [String] = []
        
        let screenTimeHours = todaysScreenTime / 3600
        
        if screenTimeHours > 6 {
            insights.append("You've been on your device for \(String(format: "%.1f", screenTimeHours)) hours today. Consider taking a digital break.")
        } else if screenTimeHours > 4 {
            insights.append("Moderate screen time today. Great job balancing digital and real-world activities!")
        } else if screenTimeHours > 0 {
            insights.append("Low screen time today. You're doing great with digital wellness!")
        }
        
        if let topApp = mostUsedApps.first {
            insights.append("Your most used app today was \(topApp.name) (\(String(format: "%.1f", topApp.usageTime / 3600))h)")
        }
        
        return insights
    }
    
    func suggestMindfulBreaks() -> [String] {
        var suggestions: [String] = []
        
        let screenTimeHours = todaysScreenTime / 3600
        
        if screenTimeHours > 4 {
            suggestions.append("Take a 5-minute break from your device")
            suggestions.append("Try a quick breathing exercise")
            suggestions.append("Step outside for some fresh air")
        }
        
        if screenTimeHours > 6 {
            suggestions.append("Consider a longer meditation session")
            suggestions.append("Read a physical book instead")
            suggestions.append("Call a friend instead of texting")
        }
        
        return suggestions
    }
    
    func refreshData() async {
        guard isAuthorized else { return }
        
        do {
            todaysScreenTime = try await getTodaysScreenTime()
            weeklyScreenTime = try await getWeeklyScreenTime()
            mostUsedApps = await getMostUsedApps()
        } catch {
            print("Failed to refresh Screen Time data: \(error)")
        }
    }
} 
