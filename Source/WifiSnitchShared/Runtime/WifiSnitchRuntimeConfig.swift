import EasyBarShared
import Foundation
import SwiftTOMLEdit

/// Resolved runtime config used by WiFiSnitch and its CLI.
public struct WiFiSnitchRuntimeConfig {
  public let configPath: String
  public let loggingEnabled: Bool
  public let loggingLevel: ProcessLogLevel
  public let loggingDirectory: String
  public let lockDirectory: String
  public let socketPath: String
  public let refreshIntervalSeconds: TimeInterval
  public let allowUnauthorizedFieldsWithoutLocation: Bool

  public static let current = load()

  /// Loads the WiFiSnitch runtime config from environment, config file, and defaults.
  public static func load() -> WiFiSnitchRuntimeConfig {
    let configPath = resolvedWifiSnitchConfigPath()
    let toml = parsedConfig(at: configPath)

    let loggingTable = toml["logging"]?.table
    let agentTable = toml["agent"]?.table
    let appTable = toml["app"]?.table

    let loggingEnabled = loggingTable?["enabled"]?.bool ?? false

    let loggingLevel = resolvedLoggingLevel(
      tomlValue: loggingTable?["level"]?.string,
      fallback: .info
    )

    let loggingDirectory =
      expandedPath(loggingTable?["directory"]?.string)
      ?? defaultWifiSnitchLoggingDirectory()

    let lockDirectory =
      expandedPath(appTable?["lock_dir"]?.string)
      ?? defaultWifiSnitchLockDirectory()

    let socketPath =
      expandedPath(agentTable?["socket_path"]?.string)
      ?? defaultWifiSnitchSocketPath()

    let refreshIntervalSeconds =
      tomlNumber(agentTable?["refresh_interval_seconds"])
      ?? 60

    let allowUnauthorizedFieldsWithoutLocation =
      agentTable?["allow_unauthorized_fields_without_location"]?.bool
      ?? false

    return WiFiSnitchRuntimeConfig(
      configPath: configPath,
      loggingEnabled: loggingEnabled,
      loggingLevel: loggingLevel,
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

/// Resolves the configured logging level from the diagnostic override or TOML.
private func resolvedLoggingLevel(
  tomlValue: String?,
  fallback: ProcessLogLevel
) -> ProcessLogLevel {
  if let raw = stringEnvironmentValue(named: WifiSnitchEnvironmentKeys.loggingLevel),
    let level = normalizedLogLevel(raw)
  {
    return level
  }

  if let tomlValue,
    let level = normalizedLogLevel(tomlValue)
  {
    return level
  }

  return fallback
}

/// Returns the normalized log level for one free-form value.
private func normalizedLogLevel(_ value: String?) -> ProcessLogLevel? {
  guard let value else { return nil }

  switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
  case "trace":
    return .trace
  case "debug":
    return .debug
  case "info":
    return .info
  case "warn", "warning":
    return .warn
  case "error":
    return .error
  default:
    return nil
  }
}

/// Returns one TOML number as a Double.
private func tomlNumber(_ value: TOMLValue?) -> Double? {
  if let double = value?.double {
    return double
  }

  if let int = value?.int {
    return Double(int)
  }

  return nil
}
