import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings
import DeviceActivity

extension DeviceActivityName{
    static let daily = Self("daily")
}

@MainActor
final class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()
    let center = DeviceActivityCenter()

    @Published private(set) var isAuthorized = false

    private init() {
        refreshAuthorizationStatus()
    }

    func refreshAuthorizationStatus() {
        let status = AuthorizationCenter.shared.authorizationStatus
        isAuthorized = (status == .approved)
    }

    func requestAuthorizationIfNeeded() async {
        // Check first
        refreshAuthorizationStatus()
        guard !isAuthorized else { return }

        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            print("Authorization failed: \(error)")
        }
        // Update after the attempt
        refreshAuthorizationStatus()
    }
    
    func startDailyMonitoring() {
           let schedule = DeviceActivitySchedule(
               intervalStart: DateComponents(hour: 0, minute: 0),
               intervalEnd: DateComponents(hour: 23, minute: 59),
               repeats: true
           )
           do {
               try center.startMonitoring(.daily, during: schedule)
           } catch {
               print("startMonitoring failed: \(error)")
           }
       }
    
    func stopDailyMonitoring() {
            center.stopMonitoring([.daily])
    }

}
