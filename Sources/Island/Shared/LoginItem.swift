import Foundation
import ServiceManagement
import Observation

/// Registers Island as a login item via SMAppService — no separate helper
/// app needed (that was the old pre-macOS-13 way). Lets the app "just be
/// there" on every boot without manually launching it or touching Xcode.
@Observable
final class LoginItem {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to \(enabled ? "register" : "unregister") login item: \(error)")
        }
    }
}
