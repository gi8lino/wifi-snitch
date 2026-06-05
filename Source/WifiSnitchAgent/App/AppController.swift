import AppKit
import EasyBarNetworkAgentCore
import EasyBarShared
import Foundation
import WiFiSnitchShared

/// App-level controller for the WiFiSnitch agent process.
///
/// This type owns macOS application concerns such as logging setup, the
/// single-instance guard, activation policy changes, and authorization prompt
/// presentation. The reusable network agent behavior lives in
/// `NetworkAgentRuntime`.
@MainActor
final class AppController: NetworkAuthorizationPromptPresenter {
  private let logger = ProcessLogger(label: "wifi-snitch-agent")
  private let instanceGuard = SingleInstanceGuard()

  private var runtime: NetworkAgentRuntime?
  private var presentedAuthorizationPrompt = false

  /// Starts the WiFiSnitch app shell and network-agent runtime.
  func start() {
    let runtimeConfig = WiFiSnitchRuntimeConfig.current

    configureLogging(runtimeConfig: runtimeConfig)

    guard acquireInstanceLock(runtimeConfig: runtimeConfig) else {
      terminateApplication()
    }

    let agentConfig = NetworkAgentRuntimeConfig(
      isEnabled: true,
      processName: "wifi-snitch",
      componentName: "wifi-snitch",
      appVersion: WiFiSnitchShared.BuildInfo.appVersion,
      configPath: runtimeConfig.configPath,
      socketPath: runtimeConfig.socketPath,
      refreshIntervalSeconds: runtimeConfig.refreshIntervalSeconds,
      allowUnauthorizedFieldsWithoutLocation: runtimeConfig.allowUnauthorizedFieldsWithoutLocation
    )

    runtime = NetworkAgentRuntime(
      config: agentConfig,
      logger: logger.child("runtime"),
      promptPresenter: self
    )

    NSApp.setActivationPolicy(.accessory)

    guard runtime?.start() == true else {
      terminateApplication()
    }
  }

  /// Stops the WiFiSnitch network-agent runtime.
  func stop() {
    runtime?.stop()
  }

  /// Prepares the app so the system location prompt can surface.
  func preparePrompt() {
    guard !presentedAuthorizationPrompt else { return }
    presentedAuthorizationPrompt = true

    let changed = NSApp.setActivationPolicy(.regular)
    logger.info(
      "wifi-snitch promoted for authorization prompt",
      .field("changed", changed)
    )
    NSApp.activate(ignoringOtherApps: true)
  }

  /// Restores accessory mode after authorization resolves.
  func restoreUI() {
    guard presentedAuthorizationPrompt else { return }
    presentedAuthorizationPrompt = false

    let changed = NSApp.setActivationPolicy(.accessory)
    logger.info(
      "wifi-snitch restored accessory mode",
      .field("changed", changed)
    )
  }

  /// Configures process logging from the WiFiSnitch runtime config.
  private func configureLogging(runtimeConfig: WiFiSnitchRuntimeConfig) {
    logger.configureRuntimeLogging(
      minimumLevel: runtimeConfig.loggingLevel,
      fileLoggingEnabled: runtimeConfig.loggingEnabled,
      fileLoggingPath: URL(fileURLWithPath: runtimeConfig.loggingDirectory)
        .appendingPathComponent("wifi-snitch.out")
        .path
    )
  }

  /// Acquires the single-instance lock for the WiFiSnitch agent process.
  private func acquireInstanceLock(runtimeConfig: WiFiSnitchRuntimeConfig) -> Bool {
    switch instanceGuard.acquireLock(
      processName: "wifi-snitch",
      directory: runtimeConfig.lockDirectory
    ) {
    case .acquired:
      return true

    case .alreadyRunning(let lockPath):
      logger.warn(
        "wifi-snitch already running",
        .field("lock_path", lockPath)
      )
      return false

    case .failed(let lockPath, let reason):
      logger.error(
        "wifi-snitch failed to acquire instance lock",
        .field("lock_path", lockPath),
        .field("reason", reason)
      )
      return false
    }
  }

  /// Terminates the application immediately.
  private func terminateApplication() -> Never {
    NSApp.terminate(nil)
    fatalError("Application should have terminated")
  }
}
