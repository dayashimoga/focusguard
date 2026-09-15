import Foundation
#if canImport(DeviceActivity)
import DeviceActivity
#endif
#if canImport(ManagedSettings)
import ManagedSettings
#endif

/// DeviceActivityMonitor extension invoked by iOS system when scheduled focus intervals start/end.
@available(iOS 16.0, *)
public class FocusActivityMonitor: DeviceActivityMonitor {

    let store = ManagedSettingsStore()

    public override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // Activated by scheduled focus interval
    }

    public override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        // Clear shields upon scheduled completion
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }

    public override func eventDidReachThreshold(for activity: DeviceActivityName, event: DeviceActivityEvent.Name) {
        super.eventDidReachThreshold(for: activity, event: event)
        // Daily app limit warning or lock threshold reached
    }
}
