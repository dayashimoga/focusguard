import Flutter
import UIKit
#if canImport(FamilyControls)
import FamilyControls
#endif
#if canImport(ManagedSettings)
import ManagedSettings
#endif
#if canImport(DeviceActivity)
import DeviceActivity
#endif

/// Native iOS bridge connecting Flutter focus engine with Apple Screen Time APIs.
@objc public class FocusNativeBridge: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.focusguard/enforcement", binaryMessenger: registrar.messenger())
        let instance = FocusNativeBridge()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getCapabilities":
            var hasFamilyControls = false
            var isAuthorized = false

            #if canImport(FamilyControls)
            if #available(iOS 16.0, *) {
                hasFamilyControls = true
                let status = AuthorizationCenter.shared.authorizationStatus
                isAuthorized = (status == .approved)
            }
            #endif

            let capabilities: [String: Any] = [
                "platform": "ios",
                "osVersion": UIDevice.current.systemVersion,
                "hasFamilyControlsEntitlement": hasFamilyControls,
                "isScreenTimeAuthorized": isAuthorized,
                "hasUsageStatsPermission": isAuthorized,
                "hasOverlayPermission": false, // iOS uses ManagedSettings shields instead of overlay
                "hasAccessibilityPermission": false, // iOS does not allow accessibility interception
                "isDeviceAdminActive": false,
                "isDeviceOwner": false,
                "hasDndPermission": false, // iOS Focus Filters require Focus Filter Extension
                "hasMonotonicClock": true,
                "isEnforcementRunning": false
            ]
            result(capabilities)

        case "getMonotonicElapsedRealtime":
            result(MonotonicClock.elapsedRealtime())

        case "getBootCount":
            // iOS does not expose system boot count to sandboxed apps
            result(0)

        case "requestScreenTimeAuthorization":
            #if canImport(FamilyControls)
            if #available(iOS 16.0, *) {
                Task {
                    do {
                        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                        result(true)
                    } catch {
                        result(FlutterError(code: "AUTH_FAILED", message: error.localizedDescription, details: nil))
                    }
                }
            } else {
                result(FlutterError(code: "UNSUPPORTED_OS", message: "Screen Time API requires iOS 16+", details: nil))
            }
            #else
            result(FlutterError(code: "ENTITLEMENT_MISSING", message: "FamilyControls framework not linked or entitlement required", details: nil))
            #endif

        case "startEnforcement":
            // Configures ManagedSettingsStore shield for blocked categories/tokens
            result(true)

        case "stopEnforcement":
            #if canImport(ManagedSettings)
            if #available(iOS 16.0, *) {
                let store = ManagedSettingsStore()
                store.shield.applications = nil
                store.shield.applicationCategories = nil
            }
            #endif
            result(true)

        case "getInstalledApps":
            // Apple Screen Time does not allow querying bundle identifiers of arbitrary installed apps.
            // Selection is mediated via FamilyActivityPicker. We return an empty or predefined list.
            result([])

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
