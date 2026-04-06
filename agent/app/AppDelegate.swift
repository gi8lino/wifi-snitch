import Cocoa
import EasyBarShared

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  let logger = ProcessLogger(label: "wifi-snitch")
  private lazy var controller = AppController(logger: logger)
  private let instanceGuard = SingleInstanceGuard()

  /// Starts the agent when the app finishes launching.
  func applicationDidFinishLaunching(_ notification: Notification) {
    let lockPath = defaultSingleInstanceLockPath(processName: "wifi-snitch")

    guard instanceGuard.acquireLock(at: lockPath) else {
      logger.warn("wifisnitch already running lock_path=\(lockPath)")
      NSApp.terminate(nil)
      return
    }

    NSApp.setActivationPolicy(.accessory)
    guard controller.start() else {
      NSApp.terminate(nil)
      return
    }
  }

  /// Stops the agent before the app terminates.
  func applicationWillTerminate(_ notification: Notification) {
    controller.stop()
  }
}
