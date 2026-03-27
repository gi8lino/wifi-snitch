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
    let components = trimmed.split(separator: " ").map(String.init)

    guard let rawCommand = components.first, !rawCommand.isEmpty else {
      return "ERR empty_request"
    }

    let command = rawCommand.lowercased()
    let args = Array(components.dropFirst())
    let payload = currentPayload()

    switch command {
    case "ping":
      return "PONG"

    case "version":
      return encoder.encodeJSON([
        "app_version": appVersion,
        "protocol_version": protocolVersion,
      ])

    case "fields":
      return encoder.availableFields.joined(separator: "\n")

    case "formats":
      return "text\njson\nlines"

    case "ssid":
      return payload.wifi.ssid.map { "OK \($0)" } ?? "EMPTY"

    case "status":
      guard let format = parseFormat(from: args) else {
        return "ERR unknown_argument"
      }

      return encoder.encodeStatus(payload, format: format)

    case "wifi":
      return encoder.encodeJSON(payload.wifi)

    case "network":
      return encoder.encodeJSON(payload.network)

    case "auth":
      return encoder.encodeJSON(payload.auth)

    case "signal":
      return encoder.encodeJSON(
        SignalPayload(
          rssi: payload.wifi.rssi,
          noise: payload.wifi.noise,
          snr: payload.wifi.snr,
          linkQuality: payload.wifi.linkQuality,
          txRate: payload.wifi.txRate
        ))

    case "debug":
      guard args.isEmpty else {
        return "ERR unknown_argument"
      }

      return encoder.encodeJSON(debugStatus())

    case "field":
      guard let fieldSpec = args.first, !fieldSpec.isEmpty else {
        return "ERR missing_field"
      }

      guard let format = parseFormat(from: Array(args.dropFirst())) else {
        return "ERR unknown_argument"
      }

      let fields = fieldSpec.split(separator: ",").map(String.init)
      return encoder.encodeFields(payload, fields: fields, format: format)

    default:
      return "ERR unknown_command"
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

  /// Parses format options from command arguments.
  private func parseFormat(from args: [String]) -> ResponseFormat? {
    var format: ResponseFormat = .json

    for arg in args {
      switch arg.lowercased() {
      case "--format=text":
        format = .text
      case "--format=lines":
        format = .lines
      case "--format=json":
        format = .json
      default:
        return nil
      }
    }

    return format
  }
}
