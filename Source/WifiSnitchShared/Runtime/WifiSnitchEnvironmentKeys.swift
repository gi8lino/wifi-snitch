import Foundation

/// Central registry of environment variable names used by WiFiSnitch processes.
///
/// Environment variables are intentionally limited to bootstrap and diagnostic
/// concerns. Runtime behavior belongs in `config.toml`; command-specific socket
/// overrides belong to the CLI `--socket` flag.
public enum WifiSnitchEnvironmentKeys {
  /// Overrides the WiFiSnitch config path.
  public static let configPath = "WIFISNITCH_CONFIG_PATH"

  /// Temporarily overrides the configured minimum log level.
  public static let loggingLevel = "WIFISNITCH_LOG_LEVEL"
}
