import Cocoa

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private let controller = AppController()
  private let instanceGuard = SingleInstanceGuard()

  /// Starts the agent when the app finishes launching.
  func applicationDidFinishLaunching(_ notification: Notification) {
    let lockPath = defaultSingleInstanceLockPath()

    guard instanceGuard.acquireLock(at: lockPath) else {
      AgentLogger.warn("wifisnitch already running lock_path=\(lockPath)")
      NSApp.terminate(nil)
      return
    }

    NSApp.setActivationPolicy(.accessory)
    controller.start()
  }

  /// Stops the agent before the app terminates.
  func applicationWillTerminate(_ notification: Notification) {
    controller.stop()
  }
}
