import Foundation
import WiFiSnitchShared

/// Handles structured protocol requests and returns structured protocol responses.
struct StatusRequestHandler {
  private let wifiProvider: WiFiProvider
  private let networkProvider: NetworkStateProvider
  private let authState: AuthState
  private let encoder: StatusFieldEncoder

  private let protocolVersion = "2"
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

  /// Parses and handles a single structured request.
  func handle(request: StatusAgentRequest) -> StatusAgentResponse {
    let payload = currentPayload()

    switch request.command {
    case .ping:
      return StatusAgentResponse(body: "PONG")

    case .version:
      return StatusAgentResponse(
        body: encoder.encodeJSON([
          "app_version": appVersion,
          "protocol_version": protocolVersion,
        ])
      )

    case .fields:
      return StatusAgentResponse(
        body: statusFieldRegistry.map(\.field.rawValue).joined(separator: "\n")
      )

    case .formats:
      return StatusAgentResponse(body: "text\njson\nlines")

    case .ssid:
      return StatusAgentResponse(body: payload.wifi.ssid.map { "OK \($0)" } ?? "EMPTY")

    case .status:
      return StatusAgentResponse(
        body: encoder.encodeStatus(payload, format: request.format ?? .json)
      )

    case .wifi:
      return StatusAgentResponse(body: encoder.encodeJSON(payload.wifi))

    case .network:
      return StatusAgentResponse(body: encoder.encodeJSON(payload.network))

    case .auth:
      return StatusAgentResponse(body: encoder.encodeJSON(payload.auth))

    case .signal:
      return StatusAgentResponse(
        body: encoder.encodeJSON(
          SignalPayload(
            rssi: payload.wifi.rssi,
            noise: payload.wifi.noise,
            snr: payload.wifi.snr,
            linkQuality: payload.wifi.linkQuality,
            txRate: payload.wifi.txRate
          )
        )
      )

    case .debug:
      return StatusAgentResponse(body: encoder.encodeJSON(debugStatus()))

    case .field:
      guard !request.fields.isEmpty else {
        return StatusAgentResponse(body: "ERR missing_field")
      }

      return StatusAgentResponse(
        body: encoder.encodeFields(
          payload,
          fields: request.fields,
          format: request.format ?? .json
        )
      )
    }
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
      "network_generated_at": payload.network.generatedAt,
      "location_authorized": payload.auth.locationAuthorized ? "true" : "false",
      "location_permission_state": payload.auth.locationPermissionState,
      "ssid_raw": String(describing: payload.wifi.ssid),
      "bssid_raw": String(describing: payload.wifi.bssid),
      "interface_name": String(describing: payload.wifi.interface),
      "hardware_address": String(describing: payload.wifi.hardwareAddress),
      "power": String(describing: payload.wifi.power),
      "service_active": String(describing: payload.wifi.serviceActive),
      "rssi_raw": String(describing: payload.wifi.rssi),
      "noise_raw": String(describing: payload.wifi.noise),
      "snr_raw": String(describing: payload.wifi.snr),
      "link_quality_raw": String(describing: payload.wifi.linkQuality),
      "tx_rate_raw": String(describing: payload.wifi.txRate),
      "channel_raw": String(describing: payload.wifi.channel),
      "channel_band_raw": String(describing: payload.wifi.channelBand),
      "channel_width_raw": String(describing: payload.wifi.channelWidth),
      "security_raw": String(describing: payload.wifi.security),
      "phy_mode_raw": String(describing: payload.wifi.phyMode),
      "interface_mode_raw": String(describing: payload.wifi.interfaceMode),
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
}
