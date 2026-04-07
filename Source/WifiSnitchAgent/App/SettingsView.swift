import EasyBarShared
import SwiftUI
import WiFiSnitchShared

struct SettingsView: View {
  /// Renders the network agent settings summary.
  var body: some View {
    AgentSettingsView(
      title: "WiFiSnitch Agent",
      socketPath: resolvedWifiSnitchSocketPath()
    )
  }
}
