import FamilyControls
import DeviceActivity
import ManagedSettings
import Foundation

enum ScheduleType: String, CaseIterable {
    case morning, work, evening
}

extension DeviceActivityName {
    static let userWindow = Self("userWindow")
}

@MainActor
final class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()
    static let suiteName = "group.com.Petals-AI"
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

    func startDailyWindow(start: DateComponents, end: DateComponents, activityName: DeviceActivityName) {
        center.stopMonitoring([activityName])  // not throwing
        let schedule = DeviceActivitySchedule(intervalStart: start,
                                              intervalEnd: end,
                                              repeats: true)
        do {
            try center.startMonitoring(activityName, during: schedule)
        } catch {
            print("startMonitoring failed: \(error)")
        }
    }

    func stopDailyWindow() {
        center.stopMonitoring(ScheduleType.allCases.map { DeviceActivityName(rawValue: $0.rawValue) })
    }
}
