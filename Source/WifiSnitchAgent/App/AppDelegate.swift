import AppKit
import EasyBarNetworkAgentCore
import EasyBarShared
import Foundation
import WiFiSnitchShared

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NetworkAuthorizationPromptPresenter {
  private let logger = ProcessLogger(label: "wifi-snitch-agent")
  private var controller: NetworkAgentController?
  private let instanceGuard = SingleInstanceGuard()
  private var presentedAuthorizationPrompt = false

  /// Starts the network agent after launch.
  func applicationDidFinishLaunching(_ notification: Notification) {
    let runtimeConfig = WiFiSnitchRuntimeConfig.current

    logger.configureRuntimeLogging(
      minimumLevel: runtimeConfig.loggingDebugEnabled ? .debug : .info,
      fileLoggingEnabled: runtimeConfig.loggingEnabled,
      fileLoggingPath: URL(fileURLWithPath: runtimeConfig.loggingDirectory)
        .appendingPathComponent("wifi-snitch.out")
        .path
    )

    let lockPath = defaultSingleInstanceLockPath(
      processName: "wifi-snitch",
      directory: runtimeConfig.lockDirectory
    )

    switch instanceGuard.acquireLock(at: lockPath) {
    case .acquired:
      break

    case .alreadyRunning:
      logger.warn("wifi-snitch already running lock_path=\(lockPath)")
      NSApp.terminate(nil)
      return

    case .failed(let reason):
      logger.error(
        "wifi-snitch failed to acquire instance lock lock_path=\(lockPath) reason=\(reason)"
      )
      NSApp.terminate(nil)
      return
    }

    let controllerConfig = NetworkAgentControllerConfig(
      isEnabled: true,
      processName: "wifi-snitch",
      componentName: "wifi-snitch",
      appVersion: WiFiSnitchShared.BuildInfo.appVersion,
      configPath: runtimeConfig.configPath,
      socketPath: runtimeConfig.socketPath,
      refreshIntervalSeconds: runtimeConfig.refreshIntervalSeconds,
      allowUnauthorizedFieldsWithoutLocation: runtimeConfig.allowUnauthorizedFieldsWithoutLocation
    )

    controller = NetworkAgentController(
      config: controllerConfig,
      logger: logger,
      promptPresenter: self
    )

    NSApp.setActivationPolicy(.accessory)
    guard controller?.start() == true else {
      NSApp.terminate(nil)
      return
    }
  }

  /// Stops the network agent before termination.
  func applicationWillTerminate(_ notification: Notification) {
    controller?.stop()
  }

  /// Prepares the app so the system location prompt can surface.
  func preparePrompt() {
    guard !presentedAuthorizationPrompt else { return }
    presentedAuthorizationPrompt = true

    let changed = NSApp.setActivationPolicy(.regular)
    logger.info("wifi-snitch promoted for authorization prompt changed=\(changed)")
    NSApp.activate(ignoringOtherApps: true)
  }

  /// Restores accessory mode after authorization resolves.
  func restoreUI() {
    guard presentedAuthorizationPrompt else { return }
    presentedAuthorizationPrompt = false

    let changed = NSApp.setActivationPolicy(.accessory)
    logger.info("wifi-snitch restored accessory mode changed=\(changed)")
  }
}
