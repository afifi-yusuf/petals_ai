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
    
    init() {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: "207124569970-gv87n0tk65h2klrip5f22umhi8f3bk7g.apps.googleusercontent.com"
        )
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
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
                    .modelContainer(for: JournalLogModel.self)
            } else {
                LoginView()
                    .onOpenURL { url in
                        GIDSignIn.sharedInstance.handle(url)
                    }
                    .environmentObject(appState)
            }
        }
    }
}
