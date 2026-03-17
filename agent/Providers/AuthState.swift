import CoreLocation
import Foundation

/// Stores the current CoreLocation authorization status.
final class AuthState {
    private let lock = NSLock()
    private var status: CLAuthorizationStatus = .notDetermined

    /// Updates the cached authorization status.
    func setStatus(_ newStatus: CLAuthorizationStatus) {
        lock.lock()
        status = newStatus
        lock.unlock()
    }

    /// Returns the cached authorization status.
    func currentStatus() -> CLAuthorizationStatus {
        lock.lock()
        defer { lock.unlock() }
        return status
    }

    /// Returns whether location access is authorized.
    func isAuthorized() -> Bool {
        switch currentStatus() {
        case .authorized, .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }

    /// Returns a normalized permission state string.
    func permissionState() -> String {
        switch currentStatus() {
        case .notDetermined:
            return "not_determined"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        case .authorized:
            return "authorized"
        case .authorizedAlways:
            return "authorized_always"
        case .authorizedWhenInUse:
            return "authorized_when_in_use"
        @unknown default:
            return "unknown"
        }
    }
}
