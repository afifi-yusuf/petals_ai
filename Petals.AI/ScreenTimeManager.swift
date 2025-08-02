import FamilyControls
import DeviceActivity
import ManagedSettings
import Foundation

extension DeviceActivityName {
    static let userWindow = Self("userWindow")
}

@MainActor
final class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()
    private let center = DeviceActivityCenter()

    @Published private(set) var isAuthorized = false

    private init() { refreshAuthorizationStatus() }

    func refreshAuthorizationStatus() {
        isAuthorized = (AuthorizationCenter.shared.authorizationStatus == .approved)
    }

    func requestAuthorizationIfNeeded() async {
        refreshAuthorizationStatus()
        guard !isAuthorized else { return }
        do { try await AuthorizationCenter.shared.requestAuthorization(for: .individual) }
        catch { print("Authorization failed: \(error)") }
        refreshAuthorizationStatus()
    }

    func startDailyWindow(start: DateComponents, end: DateComponents) {
        center.stopMonitoring([.userWindow])  // not throwing
        let schedule = DeviceActivitySchedule(intervalStart: start,
                                              intervalEnd: end,
                                              repeats: true)
        do {
            try center.startMonitoring(.userWindow, during: schedule)
        } catch {
            print("startMonitoring failed: \(error)")
        }
    }

    func stopDailyWindow() {
        center.stopMonitoring([.userWindow])
    }
}

