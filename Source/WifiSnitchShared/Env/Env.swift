import EasyBarShared
import Foundation

/// Returns the resolved socket path used by WiFiSnitch.
public func resolvedWifiSnitchSocketPath() -> String {
  expandedEnvironmentPath(named: "WIFISNITCH_SOCKET")
    ?? defaultWifiSnitchSocketPath()
}

/// Returns the default Unix socket path used by WiFiSnitch.
public func defaultWifiSnitchSocketPath() -> String {
  "/tmp/wifi-snitch/wifi-snitch.sock"
}
