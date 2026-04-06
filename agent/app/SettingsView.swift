import SwiftUI
import WiFiSnitchShared

/// Renders the app settings window.
struct SettingsView: View {
  var body: some View {
    Form {
      Text("WiFiSnitch startup is managed by Homebrew.")
        .font(.headline)

      Text("Start at login:")
        .font(.subheadline)

      Text("brew services start wifisnitch")
        .font(.footnote.monospaced())
        .textSelection(.enabled)

      Text("Stop:")
        .font(.subheadline)

      Text("brew services stop wifisnitch")
        .font(.footnote.monospaced())
        .textSelection(.enabled)

      Text("Restart:")
        .font(.subheadline)

      Text("brew services restart wifisnitch")
        .font(.footnote.monospaced())
        .textSelection(.enabled)

      Text("Socket path")
        .font(.headline)

      Text(defaultWifiSnitchSocketPath())
        .font(.footnote)
        .textSelection(.enabled)
    }
    .padding(20)
    .frame(width: 420)
  }
}
