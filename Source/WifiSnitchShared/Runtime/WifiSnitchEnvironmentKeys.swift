import Foundation

/// Central registry of environment variable names used by WiFiSnitch processes.
///
/// This file is the single source of truth for raw environment keys.
/// Parsing and precedence stay in the runtime config layer.
public enum WifiSnitchEnvironmentKeys {
  public static let configPath = "WIFISNITCH_CONFIG_PATH"

  public static let socketPath = "WIFISNITCH_SOCKET"

  public static let lockDirectory = "WIFISNITCH_LOCK_DIR"

  public static let loggingEnabled = "WIFISNITCH_LOGGING_ENABLED"
  public static let loggingDebugEnabled = "WIFISNITCH_DEBUG"
  public static let loggingDirectory = "WIFISNITCH_LOG_DIR"

  public static let refreshIntervalSeconds = "WIFISNITCH_REFRESH_INTERVAL_SECONDS"
  public static let allowUnauthorizedFieldsWithoutLocation =
    "WIFISNITCH_ALLOW_UNAUTHORIZED_FIELDS_WITHOUT_LOCATION"
}
