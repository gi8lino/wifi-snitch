import Foundation
import ServiceManagement

@MainActor
final class LoginItemManager {
    static let shared = LoginItemManager()

    private(set) var isEnabled = false
    private(set) var statusMessage: String?

    private init() {}

    /// Refreshes the cached login item state.
    func refresh() {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp

            switch service.status {
            case .enabled:
                isEnabled = true
                statusMessage = nil

            case .requiresApproval:
                isEnabled = false
                statusMessage = "Login item requires approval in System Settings."

            case .notRegistered:
                isEnabled = false
                statusMessage = nil

            case .notFound:
                isEnabled = false
                statusMessage = "Login item could not be found."

            @unknown default:
                isEnabled = false
                statusMessage = "Unknown login item status."
            }

            return
        }

        isEnabled = false
        statusMessage = "Start at login requires macOS 13 or newer."
    }

    /// Enables or disables start at login.
    func setEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp

            do {
                if enabled {
                    try service.register()
                } else {
                    try service.unregister()
                }

                refresh()
            } catch {
                refresh()

                if enabled {
                    statusMessage = "Could not enable start at login."
                } else {
                    statusMessage = "Could not disable start at login."
                }
            }

            return
        }

        isEnabled = false
        statusMessage = "Start at login requires macOS 13 or newer."
    }
}
