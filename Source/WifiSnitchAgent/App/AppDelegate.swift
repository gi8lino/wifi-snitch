import AppKit
import EasyBarNetworkAgentCore
import EasyBarShared
import Foundation
import WiFiSnitchShared

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private let logger = ProcessLogger(label: "wifi-snitch-agent")
  private var controller: NetworkAgentController?
  private let instanceGuard = SingleInstanceGuard()

  /// Starts the network agent after launch.
  func applicationDidFinishLaunching(_ notification: Notification) {
    let runtimeConfig = SharedRuntimeConfig.current
    let socketPath = resolvedWifiSnitchSocketPath()

    logger.configureRuntimeLogging(
      debugEnabled: runtimeConfig.loggingDebugEnabled,
      fileLoggingEnabled: runtimeConfig.loggingEnabled,
      fileLoggingPath: URL(fileURLWithPath: runtimeConfig.loggingDirectory)
        .appendingPathComponent("wifi-snitch.out")
        .path
    )

    let lockPath = defaultSingleInstanceLockPath(
      processName: "wifi-snitch",
      directory: runtimeConfig.lockDirectory
    )

    guard instanceGuard.acquireLock(at: lockPath) else {
      logger.warn("wifi-snitch already running lock_path=\(lockPath)")
      NSApp.terminate(nil)
      return
    }

    let controllerConfig = NetworkAgentControllerConfig(
      isEnabled: true,
      processName: "wifi-snitch",
      componentName: "wifi-snitch",
      appVersion: WiFiSnitchShared.BuildInfo.appVersion,
      configPath: runtimeConfig.configPath,
      socketPath: socketPath,
      refreshIntervalSeconds: runtimeConfig.networkAgentRefreshIntervalSeconds,
      allowUnauthorizedNonSensitiveFields: runtimeConfig
        .networkAgentAllowUnauthorizedNonSensitiveFields
    )

    controller = NetworkAgentController(config: controllerConfig, logger: logger)

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
}
