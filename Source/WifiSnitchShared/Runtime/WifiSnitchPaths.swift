import EasyBarShared
import Foundation

/// Returns the resolved WiFiSnitch config path.
public func resolvedWifiSnitchConfigPath() -> String {
  expandedEnvironmentPath(named: WifiSnitchEnvironmentKeys.configPath)
    ?? defaultWifiSnitchConfigPath()
}

/// Returns the default config path used by WiFiSnitch.
public func defaultWifiSnitchConfigPath() -> String {
  FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".config/wifisnitch/config.toml")
    .path
}

/// Returns the default Unix socket path used by WiFiSnitch.
public func defaultWifiSnitchSocketPath() -> String {
  "/tmp/wifi-snitch/wifi-snitch.sock"
}

/// Returns the default directory used for WiFiSnitch single-instance locks.
public func defaultWifiSnitchLockDirectory() -> String {
  "/tmp/wifi-snitch"
}

/// Returns the default directory used for WiFiSnitch logs.
public func defaultWifiSnitchLoggingDirectory() -> String {
  FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".local/state/wifisnitch")
    .path
}
