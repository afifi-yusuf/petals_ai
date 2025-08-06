import DeviceActivity
import ManagedSettings
import FamilyControls

final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()

    // Inside the scheduled window → allow
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        if let sel = DiscouragedSelectionStore.load() {
            let tokens = sel.applicationTokens
            store.shield.applications = tokens.isEmpty ? nil : tokens
        } else {
            store.shield.applications = nil
        }
    }

    // Outside the window → allow
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        store.shield.applications = nil
    }

    // If you also use a usage-limit event, handle it here:
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name,
                                         activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        // e.g., if event == .usageLimit { apply shields here }
    }
}
