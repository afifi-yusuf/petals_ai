// In ContentView.swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // First Tab: Health Dashboard
            NavigationView {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2.fill")
            }

            // Second Tab: Chatbot
            NavigationView {
                ChatbotView()
            }
            .tabItem {
                Label("Chat", systemImage: "message.fill")
            }
        }
        .tint(.blue) // This ensures the tab bar is visible
    }
}

#Preview {
    ContentView()
}
