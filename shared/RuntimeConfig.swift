import Foundation

/// Returns the default Unix socket path used by WiFiSnitch.
public func defaultWifiSnitchSocketPath() -> String {
  "/tmp/wifisnitch/wifisnitch.sock"
}
