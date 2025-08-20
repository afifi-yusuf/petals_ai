//
//  Petals_AIApp.swift
//  Petals.AI
//
//  Created by Yusuf Afifi on 12/06/2025.
//

import SwiftUI
import SwiftData
import GoogleSignIn  

@main
struct Petals_AIApp: App {
    @StateObject var appState = AppState()
    @StateObject var moodManager = MoodManager.shared
    
    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled = true
    @AppStorage("dailyReminderTime") private var dailyReminderTime: Date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    
    init() {
        if CommandLine.arguments.contains("--reset") {
            print("🔥 --reset flag detected")
            resetAppData()
        }
        
        if dailyReminderEnabled {
            NotificationManager.shared.requestAuthorization()
            NotificationManager.shared.scheduleDailyCheckIn(at: dailyReminderTime)
        }
    }
    func updateStreak() async {
        let modelContext = ModelContext(sharedModelContainer)
        do {
            let logs = try modelContext.fetch(
                FetchDescriptor<StreakLogModel>(sortBy: [.init(\.date, order: .reverse)])
            )
            let lastLog = logs.first
            
            // Only add a new log if the day has changed
            if !Calendar.current.isDateInToday(lastLog?.date ?? .distantPast) {
                let newLog = StreakLogModel(date: Date(), lastDate: lastLog?.date, lastStreak: lastLog?.streak ?? 0)
                modelContext.insert(newLog)
                try modelContext.save()
                moodManager.currentStreak = newLog.streak
            } else {
                moodManager.currentStreak = lastLog?.streak ?? 0
            }
            
        } catch {
            print("Failed to update streak: \(error)")
        }
    }

    func resetAppData(){
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            JournalLogModel.self,
            StreakLogModel.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if appState.isSignedIn {
                ContentView()
                    .onOpenURL { url in
                        GIDSignIn.sharedInstance.handle(url)
                    }
                    .environmentObject(appState)
                    .environmentObject(moodManager)
                    .fullScreenCover(isPresented: $moodManager.showingMoodPrompt) {
                        DailyMoodPromptView()
                    }
                    .modelContainer(sharedModelContainer)
                    .task {
                        await updateStreak()
                    }
            } else {
                fatalError("ERROR")
            }
        }
    }
}
