import Foundation
import WiFiSnitchShared

/// Handles protocol requests and returns protocol responses.
struct StatusRequestHandler {
    private let wifiProvider: WiFiProvider
    private let networkProvider: NetworkStateProvider
    private let authState: AuthState
    private let encoder: StatusFieldEncoder

    private let protocolVersion = "1"
    private let appVersion = BuildInfo.appVersion

    /// Creates a request handler with all providers.
    init(
        wifiProvider: WiFiProvider,
        networkProvider: NetworkStateProvider,
        authState: AuthState,
        encoder: StatusFieldEncoder
    ) {
        self.wifiProvider = wifiProvider
        self.networkProvider = networkProvider
        self.authState = authState
        self.encoder = encoder
    }

    /// Parses and handles a single protocol request.
    func handle(request: String) -> String {
        let trimmed = request.trimmingCharacters(in: .whitespacesAndNewlines)
        let upper = trimmed.uppercased()

        if upper == "PING" {
            return "PONG"
        }

        if upper == "VERSION" {
            return encoder.encodeJSON([
                "app_version": appVersion,
                "protocol_version": protocolVersion,
            ])
        }

        if upper == "FIELDS" {
            return encoder.availableFields.joined(separator: "\n")
        }

        if upper == "FORMATS" {
            return "text\njson\nlines"
        }

        if upper == "GET_DEBUG" {
            return encoder.encodeJSON(debugStatus())
        }

        let payload = currentPayload()

        if upper == "GET_SSID" {
            return payload.wifi.ssid.map { "OK \($0)" } ?? "EMPTY"
        }

        if upper == "GET_STATUS" {
            return encoder.encodeStatus(payload, format: .json)
        }

        if upper.hasPrefix("GET_STATUS ") {
            let args = trimmed.split(separator: " ").dropFirst().map(String.init)
            let format = parseFormat(from: args)
            return encoder.encodeStatus(payload, format: format)
        }

        if upper == "GET_WIFI" {
            return encoder.encodeJSON(payload.wifi)
        }

        if upper == "GET_NETWORK" {
            return encoder.encodeJSON(payload.network)
        }

        if upper == "GET_AUTH" {
            return encoder.encodeJSON(payload.auth)
        }

        if upper == "GET_SIGNAL" {
            return encoder.encodeJSON(SignalPayload(
                rssi: payload.wifi.rssi,
                noise: payload.wifi.noise,
                snr: payload.wifi.snr,
                linkQuality: payload.wifi.linkQuality,
                txRate: payload.wifi.txRate
            ))
        }

        let components = trimmed.split(separator: " ").map(String.init)
        guard !components.isEmpty else {
            return "ERR empty_request"
        }

        guard components[0].uppercased() == "GET" else {
            return "ERR unknown_command"
        }

        guard components.count >= 2 else {
            return "ERR missing_field"
        }

        let fieldSpec = components[1]
        let format = parseFormat(from: components.dropFirst(2))
        let fields = fieldSpec.split(separator: ",").map(String.init)

        return encoder.encodeFields(payload, fields: fields, format: format)
    }

    /// Builds the current full status payload.
    private func currentPayload() -> StatusPayload {
        StatusPayload(
            wifi: wifiProvider.currentSnapshot(),
            network: networkProvider.currentNetwork(),
            auth: AuthPayload(
                locationAuthorized: authState.isAuthorized(),
                locationPermissionState: authState.permissionState()
            )
        )
    }

    /// Builds debug data from all providers.
    private func debugStatus() -> [String: String] {
        let payload = currentPayload()
        let networkDebug = networkProvider.debugInfo()

        var result: [String: String] = [
            "socket_path": defaultSocketPath(),
            "location_authorized": payload.auth.locationAuthorized ? "true" : "false",
            "location_permission_state": payload.auth.locationPermissionState,
            "ssid_raw": String(describing: payload.wifi.ssid),
            "bssid_raw": String(describing: payload.wifi.bssid),
            "interface_name": String(describing: payload.wifi.interface),
            "power": String(describing: payload.wifi.power),
            "rssi_raw": String(describing: payload.wifi.rssi),
            "noise_raw": String(describing: payload.wifi.noise),
            "snr_raw": String(describing: payload.wifi.snr),
            "link_quality_raw": String(describing: payload.wifi.linkQuality),
            "tx_rate_raw": String(describing: payload.wifi.txRate),
            "channel_raw": String(describing: payload.wifi.channel),
            "channel_band_raw": String(describing: payload.wifi.channelBand),
            "security_raw": String(describing: payload.wifi.security),
            "phy_mode_raw": String(describing: payload.wifi.phyMode),
            "country_code_raw": String(describing: payload.wifi.countryCode),
            "roaming": payload.wifi.roaming ? "true" : "false",
            "ssid_changed_at": payload.wifi.ssidChangedAt ?? "",
            "interface_changed_at": payload.wifi.interfaceChangedAt ?? "",
            "primary_interface": String(describing: payload.network.primaryInterface),
            "active_tunnel_interface": String(describing: payload.network.activeTunnelInterface),
            "active_tunnel_interfaces": payload.network.activeTunnelInterfaces.joined(separator: ","),
            "primary_interface_is_tunnel": payload.network.primaryInterfaceIsTunnel ? "true" : "false",
        ]

        for (key, value) in networkDebug {
            result[key] = value
        }

        return result
    }

    /// Parses the requested response format.
    private func parseFormat<S: Sequence>(from args: S) -> ResponseFormat where S.Element == String {
        for arg in args {
            switch arg.lowercased() {
            case "--format=text":
                return .text
            case "--format=lines":
                return .lines
            case "--format=json":
                return .json
            default:
                continue
            }
        }

        return .json
    }
}
