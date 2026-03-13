import Cocoa
import CoreLocation

final class AppDelegate: NSObject, NSApplicationDelegate, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var server: StatusSocketServer?

    /// Starts the socket server when the app finishes launching.
    func applicationDidFinishLaunching(_ notification: Notification) {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()

        let socketPath = Self.makeSocketPath()
        server = StatusSocketServer(
            socketPath: socketPath,
            authorizationStatus: locationManager.authorizationStatus
        )
        server?.start()
    }

    /// Updates the cached location authorization state.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        server?.setAuthorizationStatus(manager.authorizationStatus)
    }

    /// Returns the Unix socket path used by the agent.
    private static func makeSocketPath() -> String {
        if let override = ProcessInfo.processInfo.environment["WIFISNITCH_SOCKET"]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !override.isEmpty {
            return override
        }

        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = caches.appendingPathComponent("wifisnitch", isDirectory: true)
        return dir.appendingPathComponent("wifisnitch.sock").path
    }
}
