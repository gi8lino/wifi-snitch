import CoreWLAN
import Foundation

/// Collects Wi-Fi information from CoreWLAN and keeps small change-tracking state.
final class WiFiProvider {
    private let lock = NSLock()

    private var lastSSID: String?
    private var lastBSSID: String?
    private var lastInterface: String?

    private var ssidChangedAt: Date?
    private var interfaceChangedAt: Date?
    private var roaming = false

    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// Returns the current Wi-Fi snapshot.
    func currentSnapshot() -> WiFiPayload {
        let iface = CWWiFiClient.shared().interface()

        let ssid = normalized(iface?.ssid())
        let bssid = normalized(iface?.bssid())
        let interfaceName = normalized(iface?.interfaceName)
        let power = iface?.powerOn()

        let rssi = validMeasurement(iface?.rssiValue())
        let noise = validMeasurement(iface?.noiseMeasurement())
        let snr = makeSNR(rssi: rssi, noise: noise)
        let linkQuality = makeLinkQuality(snr: snr)

        let txRate = iface.map { Int($0.transmitRate()) }

        let channelInfo = iface?.wlanChannel()
        let channel = channelInfo.map { Int($0.channelNumber) }
        let channelBand = channelInfo.map { channelBandString($0.channelBand) }

        let security = iface.map(securityString)

        let phyMode: String?
        if let iface {
            phyMode = phyModeString(iface.activePHYMode())
        } else {
            phyMode = nil
        }

        let countryCode = normalized(iface?.countryCode())

        let state = updateChangeTracking(ssid: ssid, bssid: bssid, interface: interfaceName)

        return WiFiPayload(
            ssid: ssid,
            bssid: bssid,
            interface: interfaceName,
            power: power,
            rssi: rssi,
            noise: noise,
            snr: snr,
            linkQuality: linkQuality,
            txRate: txRate,
            channel: channel,
            channelBand: channelBand,
            security: security,
            phyMode: phyMode,
            countryCode: countryCode,
            roaming: state.roaming,
            ssidChangedAt: state.ssidChangedAt,
            interfaceChangedAt: state.interfaceChangedAt
        )
    }

    /// Updates cached change-tracking state and returns the current derived values.
    private func updateChangeTracking(ssid: String?, bssid: String?, interface: String?) -> (roaming: Bool, ssidChangedAt: String?, interfaceChangedAt: String?) {
        lock.lock()
        defer { lock.unlock() }

        let now = Date()

        if lastSSID != ssid {
            ssidChangedAt = now
        }

        if lastInterface != interface {
            interfaceChangedAt = now
        }

        // Roaming means same SSID, different BSSID.
        if lastSSID == ssid, ssid != nil, lastBSSID != nil, bssid != nil, lastBSSID != bssid {
            roaming = true
        } else {
            roaming = false
        }

        lastSSID = ssid
        lastBSSID = bssid
        lastInterface = interface

        return (
            roaming: roaming,
            ssidChangedAt: ssidChangedAt.map(Self.dateFormatter.string(from:)),
            interfaceChangedAt: interfaceChangedAt.map(Self.dateFormatter.string(from:))
        )
    }

    /// Returns a trimmed string or nil for empty input.
    private func normalized(_ value: String?) -> String? {
        guard let value else { return nil }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Filters out empty signal values.
    private func validMeasurement(_ value: Int?) -> Int? {
        guard let value, value != 0 else { return nil }
        return value
    }

    /// Returns signal-to-noise ratio.
    private func makeSNR(rssi: Int?, noise: Int?) -> Int? {
        guard let rssi, let noise else { return nil }
        return rssi - noise
    }

    /// Returns a rough 0...100 link quality score.
    private func makeLinkQuality(snr: Int?) -> Int? {
        guard let snr else { return nil }
        return min(max((snr - 10) * 4, 0), 100)
    }

    /// Returns a normalized Wi-Fi band string.
    private func channelBandString(_ band: CWChannelBand) -> String {
        let raw = String(describing: band).lowercased()

        switch raw {
        case "band2ghz":
            return "2.4ghz"
        case "band5ghz":
            return "5ghz"
        case "band6ghz":
            return "6ghz"
        case "bandunknown":
            return "unknown"
        default:
            return "unknown"
        }
    }

    /// Returns a normalized security string from the interface.
    private func securityString(_ interface: CWInterface) -> String {
        let raw = String(describing: interface.security())
            .replacingOccurrences(of: "CWSecurity", with: "")
            .replacingOccurrences(of: ".", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch raw {
        case "none":
            return "open"
        case "wep":
            return "wep"
        case "dynamicwep":
            return "dynamic_wep"
        case "wpapersonal":
            return "wpa_personal"
        case "wpapersonalmixed":
            return "wpa_personal_mixed"
        case "wpa2personal":
            return "wpa2_personal"
        case "personal":
            return "personal"
        case "wpaenterprise":
            return "wpa_enterprise"
        case "wpaenterprisemixed":
            return "wpa_enterprise_mixed"
        case "wpa2enterprise":
            return "wpa2_enterprise"
        case "enterprise":
            return "enterprise"
        case "wpa3personal":
            return "wpa3_personal"
        case "wpa3transition":
            return "wpa3_transition"
        case "wpa3enterprise":
            return "wpa3_enterprise"
        case "owe":
            return "enhanced_open"
        case "owetransition":
            return "enhanced_open_transition"
        case "unknown":
            return "unknown"
        default:
            return raw.isEmpty ? "unknown" : raw
        }
    }

    /// Returns a normalized PHY mode string.
    private func phyModeString(_ mode: CWPHYMode) -> String {
        let raw = String(describing: mode)
            .replacingOccurrences(of: "CWPHYMode", with: "")
            .replacingOccurrences(of: ".", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        switch raw.lowercased() {
        case "modenone", "none":
            return "none"
        case "mode11a", "11a":
            return "802.11a"
        case "mode11b", "11b":
            return "802.11b"
        case "mode11g", "11g":
            return "802.11g"
        case "mode11n", "11n":
            return "802.11n"
        case "mode11ac", "11ac":
            return "802.11ac"
        case "mode11ax", "11ax":
            return "802.11ax"
        default:
            return raw.isEmpty ? "unknown" : raw.lowercased()
        }
    }
}
