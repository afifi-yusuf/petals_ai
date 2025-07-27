
import SwiftUI
import HealthKit

struct SettingsView: View {
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
                            
                            Text("Manage your app settings and permissions.")
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
                            Text("Done")
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
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
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
            await screenTimeManager.requestAuthorization()
            await MainActor.run {
                isRequestingScreenTime = false
            }
        }
    }
}
