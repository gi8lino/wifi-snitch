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
  public let allowUnauthorizedFieldsWithoutLocation: Bool

  public static let current = load()

  /// Loads the WiFiSnitch runtime config from env, config file, and defaults.
  public static func load() -> WiFiSnitchRuntimeConfig {
    let configPath = resolvedWifiSnitchConfigPath()
    let toml = parsedConfig(at: configPath)

    let loggingTable = toml["logging"]?.table
    let agentTable = toml["agent"]?.table
    let appTable = toml["app"]?.table

    let loggingEnabled =
      boolEnvironmentValue(named: WifiSnitchEnvironmentKeys.loggingEnabled)
      ?? loggingTable?["enabled"]?.bool
      ?? false

    let loggingDebugEnabled =
      boolEnvironmentValue(named: WifiSnitchEnvironmentKeys.loggingDebugEnabled)
      ?? loggingTable?["debug"]?.bool
      ?? false

    let loggingDirectory =
      expandedEnvironmentPath(named: WifiSnitchEnvironmentKeys.loggingDirectory)
      ?? expandedPath(loggingTable?["directory"]?.string)
      ?? defaultWifiSnitchLoggingDirectory()

    let lockDirectory =
      expandedEnvironmentPath(named: WifiSnitchEnvironmentKeys.lockDirectory)
      ?? expandedPath(appTable?["lock_dir"]?.string)
      ?? defaultWifiSnitchLockDirectory()

    let socketPath =
      expandedEnvironmentPath(named: WifiSnitchEnvironmentKeys.socketPath)
      ?? expandedPath(agentTable?["socket_path"]?.string)
      ?? defaultWifiSnitchSocketPath()

    let refreshIntervalSeconds =
      timeIntervalEnvironmentValue(named: WifiSnitchEnvironmentKeys.refreshIntervalSeconds)
      ?? agentTable?["refresh_interval_seconds"]?.double
      ?? 60

    let allowUnauthorizedFieldsWithoutLocation =
      boolEnvironmentValue(named: WifiSnitchEnvironmentKeys.allowUnauthorizedFieldsWithoutLocation)
      ?? agentTable?["allow_unauthorized_fields_without_location"]?.bool
      ?? false

    return WiFiSnitchRuntimeConfig(
      configPath: configPath,
      loggingEnabled: loggingEnabled,
      loggingDebugEnabled: loggingDebugEnabled,
      loggingDirectory: loggingDirectory,
      lockDirectory: lockDirectory,
      socketPath: socketPath,
      refreshIntervalSeconds: refreshIntervalSeconds,
      allowUnauthorizedFieldsWithoutLocation: allowUnauthorizedFieldsWithoutLocation
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
