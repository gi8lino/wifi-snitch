import CoreWLAN
import Foundation

/// Collects Wi-Fi information.
struct WiFiProvider {
    /// Returns the current Wi-Fi payload.
    func currentWiFi() -> WiFiPayload {
        let iface = CWWiFiClient.shared().interface()
        let interfaceName = normalized(iface?.interfaceName)
        let txRate = iface.map { Int($0.transmitRate()) }

        return WiFiPayload(
            ssid: currentSSID(),
            interface: interfaceName,
            power: iface?.powerOn(),
            rssi: validMeasurement(iface?.rssiValue()),
            noise: validMeasurement(iface?.noiseMeasurement()),
            txRate: txRate
        )
    }

    /// Returns the current SSID.
    private func currentSSID() -> String? {
        guard let iface = CWWiFiClient.shared().interface(),
              let ssid = iface.ssid(),
              !ssid.isEmpty else {
            return nil
        }
        return ssid
    }

    /// Returns a trimmed string or nil for empty input.
    private func normalized(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Returns nil for empty signal measurements.
    private func validMeasurement(_ value: Int?) -> Int? {
        guard let value, value != 0 else { return nil }
        return value
    }
}
