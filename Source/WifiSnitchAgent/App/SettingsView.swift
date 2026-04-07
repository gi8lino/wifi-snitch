import EasyBarShared
import SwiftUI
import WiFiSnitchShared

struct SettingsView: View {
  private let runtimeConfig = WiFiSnitchRuntimeConfig.current

  /// Renders the network agent settings summary.
  var body: some View {
    AgentSettingsView(
      title: "WiFiSnitch Agent",
      socketPath: runtimeConfig.socketPath
    )
  }
}
