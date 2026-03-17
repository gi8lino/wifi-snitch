import SwiftUI
import WiFiSnitchShared

/// Renders the app settings window.
struct SettingsView: View {
    @State private var isEnabled = false
    @State private var statusMessage: String?

    var body: some View {
        Form {
            Toggle("Start at login", isOn: bindingForLoginItem)

            if let statusMessage, !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Text("Socket path")
                .font(.headline)

            Text(defaultSocketPath())
                .font(.footnote)
                .textSelection(.enabled)
        }
        .padding(20)
        .frame(width: 420)
        .onAppear {
            refreshLoginItemState()
        }
    }

    /// Binds the toggle to the login item manager.
    private var bindingForLoginItem: Binding<Bool> {
        Binding(
            get: { isEnabled },
            set: { newValue in
                setLoginItemEnabled(newValue)
            }
        )
    }

    /// Refreshes the cached login item state for the UI.
    private func refreshLoginItemState() {
        let manager = LoginItemManager.shared
        manager.refresh()

        isEnabled = manager.isEnabled
        statusMessage = manager.statusMessage
    }

    /// Updates the login item state and refreshes the UI.
    private func setLoginItemEnabled(_ enabled: Bool) {
        let manager = LoginItemManager.shared
        manager.setEnabled(enabled)

        isEnabled = manager.isEnabled
        statusMessage = manager.statusMessage
    }
}
