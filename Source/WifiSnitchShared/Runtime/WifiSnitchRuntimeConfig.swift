import EasyBarShared
import Foundation
import TOMLKit

/// Resolved runtime config used by WiFiSnitch and its CLI.
public struct WiFiSnitchRuntimeConfig {
  public let configPath: String
  public let loggingEnabled: Bool
  public let loggingDebugEnabled: Bool
  public let loggingDirectory: String
  public let lockDirectory: String
  public let socketPath: String
  public let refreshIntervalSeconds: TimeInterval
  public let allowUnauthorizedNonSensitiveFields: Bool

  public static let current = load()

  /// Loads the WiFiSnitch runtime config from env, config file, and defaults.
  public static func load() -> WiFiSnitchRuntimeConfig {
    let configPath = resolvedWifiSnitchConfigPath()
    let toml = parsedConfig(at: configPath)

    let loggingTable = toml["logging"]?.table
    let agentTable = toml["agent"]?.table
    let appTable = toml["app"]?.table

    let loggingEnabled =
      boolEnvironmentValue(named: "WIFISNITCH_LOGGING_ENABLED")
      ?? loggingTable?["enabled"]?.bool
      ?? false

    let loggingDebugEnabled =
      boolEnvironmentValue(named: "WIFISNITCH_DEBUG")
      ?? loggingTable?["debug"]?.bool
      ?? false

    let loggingDirectory =
      expandedEnvironmentPath(named: "WIFISNITCH_LOG_DIR")
      ?? expandedPath(loggingTable?["directory"]?.string)
      ?? defaultWifiSnitchLoggingDirectory()

    let lockDirectory =
      expandedEnvironmentPath(named: "WIFISNITCH_LOCK_DIR")
      ?? expandedPath(appTable?["lock_dir"]?.string)
      ?? defaultWifiSnitchLockDirectory()

    let socketPath =
      expandedEnvironmentPath(named: "WIFISNITCH_SOCKET")
      ?? expandedPath(agentTable?["socket_path"]?.string)
      ?? defaultWifiSnitchSocketPath()

    let refreshIntervalSeconds =
      timeIntervalEnvironmentValue(named: "WIFISNITCH_REFRESH_INTERVAL_SECONDS")
      ?? agentTable?["refresh_interval_seconds"]?.double
      ?? 60

    let allowUnauthorizedNonSensitiveFields =
      boolEnvironmentValue(named: "WIFISNITCH_ALLOW_UNAUTHORIZED_NON_SENSITIVE_FIELDS")
      ?? agentTable?["allow_unauthorized_non_sensitive_fields"]?.bool
      ?? false

    return WiFiSnitchRuntimeConfig(
      configPath: configPath,
      loggingEnabled: loggingEnabled,
      loggingDebugEnabled: loggingDebugEnabled,
      loggingDirectory: loggingDirectory,
      lockDirectory: lockDirectory,
      socketPath: socketPath,
      refreshIntervalSeconds: refreshIntervalSeconds,
      allowUnauthorizedNonSensitiveFields: allowUnauthorizedNonSensitiveFields
    )
  }
}

/// Returns one parsed TOML table or an empty table when loading fails.
private func parsedConfig(at path: String) -> TOMLTable {
  guard
    let text = try? String(contentsOfFile: path, encoding: .utf8),
    let table = try? TOMLTable(string: text)
  else {
    return TOMLTable()
  }

  return table
}
