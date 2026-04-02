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
    let effectivePayload = effectivePayload(from: payload)
    let permissionState = payload.auth.locationPermissionState

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
      guard payload.auth.locationAuthorized else {
        return permissionDeniedResponse(permissionState: permissionState)
      }

      return StatusAgentResponse(body: payload.wifi.ssid.map { "OK \($0)" } ?? "EMPTY")

    case .status:
      return StatusAgentResponse(
        body: encoder.encodeStatus(effectivePayload, format: request.format ?? .json)
      )

    case .wifi:
      guard payload.auth.locationAuthorized else {
        return permissionDeniedResponse(permissionState: permissionState)
      }

      return StatusAgentResponse(body: encoder.encodeJSON(payload.wifi))

    case .network:
      return StatusAgentResponse(body: encoder.encodeJSON(payload.network))

    case .auth:
      return StatusAgentResponse(body: encoder.encodeJSON(payload.auth))

    case .signal:
      guard payload.auth.locationAuthorized else {
        return permissionDeniedResponse(permissionState: permissionState)
      }

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
      return StatusAgentResponse(body: encoder.encodeJSON(debugStatus(payload: effectivePayload)))

    case .field:
      guard !request.fields.isEmpty else {
        return StatusAgentResponse(body: "ERR missing_field")
      }

      guard payload.auth.locationAuthorized || !request.fields.contains(where: requiresLocationAuthorization)
      else {
        return permissionDeniedResponse(permissionState: permissionState)
      }

      return StatusAgentResponse(
        body: encoder.encodeFields(
          effectivePayload,
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

  /// Returns one payload with Wi-Fi-sensitive fields removed when auth is unavailable.
  private func effectivePayload(from payload: StatusPayload) -> StatusPayload {
    guard !payload.auth.locationAuthorized else { return payload }

    return StatusPayload(
      wifi: WiFiPayload(
        ssid: nil,
        bssid: nil,
        interface: nil,
        hardwareAddress: nil,
        power: nil,
        serviceActive: nil,
        rssi: nil,
        noise: nil,
        snr: nil,
        linkQuality: nil,
        txRate: nil,
        channel: nil,
        channelBand: nil,
        channelWidth: nil,
        security: nil,
        phyMode: nil,
        interfaceMode: nil,
        countryCode: nil,
        roaming: false,
        ssidChangedAt: nil,
        interfaceChangedAt: nil
      ),
      network: payload.network,
      auth: payload.auth
    )
  }

  /// Returns whether a requested field depends on location authorization.
  private func requiresLocationAuthorization(_ field: StatusField) -> Bool {
    field.rawValue.hasPrefix("wifi.")
  }

  /// Returns one permission-denied response.
  private func permissionDeniedResponse(permissionState: String) -> StatusAgentResponse {
    StatusAgentResponse(body: "ERR permission_denied:\(permissionState)")
  }

  /// Builds debug data from all providers.
  private func debugStatus(payload: StatusPayload) -> [String: String] {
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
