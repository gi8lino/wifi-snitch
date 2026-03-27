import SwiftUI

/// The application entry point.
@main
struct WifiSnitchApp: App {
  /// Bridges SwiftUI app lifecycle with AppKit lifecycle hooks.
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    Settings {
      SettingsView()
    }
  }
}
