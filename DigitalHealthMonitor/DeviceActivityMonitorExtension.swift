import Foundation
import DeviceActivity
import ManagedSettings
import FamilyControls

// Duplicating ScheduleStore logic here to avoid creating a new file
private enum ScheduleStore {
    static let suiteName = "group.com.Petals-AI"
    static let morningKey = "morningSelectionV2"
    static let workKey = "workSelectionV2"
    static let eveningKey = "eveningSelectionV2"
    static let customKey = "customSelectionV2"
    static let customStartTimeKey = "customStartTimeV2"
    static let customEndTimeKey = "customEndTimeV2"

    static func load() -> (morning: FamilyActivitySelection, work: FamilyActivitySelection, evening: FamilyActivitySelection, custom: FamilyActivitySelection, customStartTime: Date, customEndTime: Date) {
        let defaults = UserDefaults(suiteName: suiteName)
        let morning = loadSelection(forKey: morningKey, from: defaults)
        let work = loadSelection(forKey: workKey, from: defaults)
        let evening = loadSelection(forKey: eveningKey, from: defaults)
        let custom = loadSelection(forKey: customKey, from: defaults)
        let customStartTime = defaults?.object(forKey: customStartTimeKey) as? Date ?? Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!
        let customEndTime = defaults?.object(forKey: customEndTimeKey) as? Date ?? Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!
        return (morning, work, evening, custom, customStartTime, customEndTime)
    }

    private static func loadSelection(forKey key: String, from defaults: UserDefaults?) -> FamilyActivitySelection {
        guard let data = defaults?.data(forKey: key),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return FamilyActivitySelection()
        }
        return selection
    }
}


final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        let schedules = ScheduleStore.load()
        let selection: FamilyActivitySelection
        
        switch activity.rawValue {
        case "morning":
            selection = schedules.morning
        case "work":
            selection = schedules.work
        case "evening":
            selection = schedules.evening
        case "custom":
            selection = schedules.custom
        default:
            selection = FamilyActivitySelection()
        }
        
        let tokens = selection.applicationTokens
        store.shield.applications = tokens.isEmpty ? nil : tokens
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        store.shield.applications = nil
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name,
                                         activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        // e.g., if event == .usageLimit { apply shields here }
    }
}
