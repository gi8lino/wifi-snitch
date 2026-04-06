import EasyBarShared
import Foundation

/// Returns the default Unix socket path used by WiFiSnitch.
public func defaultWifiSnitchSocketPath() -> String {
  "/tmp/wifisnitch/wifisnitch.sock"
}

/// Returns the default directory used by WiFiSnitch lock files.
public func defaultWifiSnitchLockDirectory() -> String {
  if let override = ProcessInfo.processInfo.environment["WIFISNITCH_LOCK_DIR"]?
    .trimmingCharacters(in: .whitespacesAndNewlines),
    !override.isEmpty
  {
    return NSString(string: override).expandingTildeInPath
  }

  return "/tmp/wifisnitch"
}

/// Returns the default single-instance lock path used by WiFiSnitch.
public func defaultWifiSnitchLockPath() -> String {
  defaultSingleInstanceLockPath(
    processName: "wifi-snitch",
    directory: defaultWifiSnitchLockDirectory()
  )
}
