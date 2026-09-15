import Foundation
import UIKit
#if canImport(ManagedSettingsUI)
import ManagedSettingsUI
#endif
#if canImport(ManagedSettings)
import ManagedSettings
#endif

/// Customizes Apple's native system shield shown when restricted apps are tapped.
@available(iOS 16.0, *)
public class FocusShieldConfiguration: ShieldConfigurationDataSource {

    public override func configuration(shielding application: Application) -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor(red: 0.05, green: 0.07, blue: 0.09, alpha: 1.0),
            icon: UIImage(systemName: "shield.fill"),
            title: ShieldConfiguration.Label(text: "Focus Session Active", color: .white),
            subtitle: ShieldConfiguration.Label(text: "This app is restricted by your FocusGuard profile.", color: .lightGray),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Return to FocusGuard", color: .white),
            primaryButtonBackgroundColor: UIColor(red: 0.39, green: 0.40, blue: 0.95, alpha: 1.0),
            secondaryButtonLabel: ShieldConfiguration.Label(text: "Emergency Access", color: .systemRed)
        )
    }
}
