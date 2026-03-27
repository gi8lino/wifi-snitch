import Foundation

/// Returns the default Unix socket path used by WiFiSnitch.
public func defaultSocketPath() -> String {
  if let override = ProcessInfo.processInfo.environment["WIFISNITCH_SOCKET"]?
    .trimmingCharacters(in: .whitespacesAndNewlines),
    !override.isEmpty
  {
    return override
  }

  let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
  let dir = caches.appendingPathComponent("wifisnitch", isDirectory: true)
  return dir.appendingPathComponent("wifisnitch.sock").path
}
