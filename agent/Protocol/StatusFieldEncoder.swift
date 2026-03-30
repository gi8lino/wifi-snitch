import Foundation
import WiFiSnitchShared

/// Encodes status payloads into protocol responses.
struct StatusFieldEncoder {
  private let availableFields = Set(StatusField.allCases)

  /// Flattens the status payload into dot-separated fields.
  func flatten(_ payload: StatusPayload) -> [String: String] {
    var result: [String: String] = [:]

    put(&result, .wifiSSID, payload.wifi.ssid)
    put(&result, .wifiBSSID, payload.wifi.bssid)
    put(&result, .wifiInterface, payload.wifi.interface)
    put(&result, .wifiHardwareAddress, payload.wifi.hardwareAddress)
    put(&result, .wifiPower, payload.wifi.power)
    put(&result, .wifiServiceActive, payload.wifi.serviceActive)
    put(&result, .wifiRSSI, payload.wifi.rssi)
    put(&result, .wifiNoise, payload.wifi.noise)
    put(&result, .wifiSNR, payload.wifi.snr)
    put(&result, .wifiLinkQuality, payload.wifi.linkQuality)
    put(&result, .wifiTxRate, payload.wifi.txRate)
    put(&result, .wifiChannel, payload.wifi.channel)
    put(&result, .wifiChannelBand, payload.wifi.channelBand)
    put(&result, .wifiChannelWidth, payload.wifi.channelWidth)
    put(&result, .wifiSecurity, payload.wifi.security)
    put(&result, .wifiPhyMode, payload.wifi.phyMode)
    put(&result, .wifiInterfaceMode, payload.wifi.interfaceMode)
    put(&result, .wifiCountryCode, payload.wifi.countryCode)
    put(&result, .wifiRoaming, payload.wifi.roaming)
    put(&result, .wifiSSIDChangedAt, payload.wifi.ssidChangedAt)
    put(&result, .wifiInterfaceChangedAt, payload.wifi.interfaceChangedAt)

    put(&result, .networkPrimaryInterface, payload.network.primaryInterface)
    put(&result, .networkActiveTunnelInterface, payload.network.activeTunnelInterface)
    put(&result, .networkActiveTunnelInterfaces, payload.network.activeTunnelInterfaces)
    put(&result, .networkPrimaryInterfaceIsTunnel, payload.network.primaryInterfaceIsTunnel)
    put(&result, .networkIPv4Address, payload.network.ipv4Address)
    put(&result, .networkIPv6Address, payload.network.ipv6Address)
    put(&result, .networkDefaultGateway, payload.network.defaultGateway)
    put(&result, .networkDNSServers, payload.network.dnsServers)
    put(&result, .networkInternetReachable, payload.network.internetReachable)
    put(&result, .networkCaptivePortal, payload.network.captivePortal)

    put(&result, .authLocationAuthorized, payload.auth.locationAuthorized)
    put(&result, .authLocationPermissionState, payload.auth.locationPermissionState)

    return result
  }

  /// Encodes the full status in the requested format.
  func encodeStatus(_ payload: StatusPayload, format: ResponseFormat) -> String {
    switch format {
    case .json:
      return encodeJSON(payload)

    case .lines:
      return flatten(payload)
        .sorted(by: { $0.key < $1.key })
        .map { "\($0.key)=\($0.value)" }
        .joined(separator: "\n")

    case .text:
      return "ERR text_requires_single_field"
    }
  }

  /// Encodes selected fields in the requested format.
  func encodeFields(_ payload: StatusPayload, fields: [StatusField], format: ResponseFormat)
    -> String
  {
    let flat = flatten(payload)

    for field in fields where !availableFields.contains(field) {
      return "ERR unknown_field \(field.rawValue)"
    }

    switch format {
    case .text:
      guard fields.count == 1 else {
        return "ERR text_requires_single_field"
      }
      return flat[fields[0].rawValue] ?? "EMPTY"

    case .lines:
      return fields.map { "\($0.rawValue)=\(flat[$0.rawValue] ?? "")" }.joined(separator: "\n")

    case .json:
      var dict: [String: String] = [:]

      for field in fields {
        if let value = flat[field.rawValue] {
          dict[field.rawValue] = value
        }
      }

      return encodeJSON(dict)
    }
  }

  /// Encodes any encodable value as JSON.
  func encodeJSON<T: Encodable>(_ value: T) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]

    guard let data = try? encoder.encode(value),
      let text = String(data: data, encoding: .utf8)
    else {
      return "ERR encode_failed"
    }

    return text
  }

  /// Stores an optional scalar value in a flattened field map.
  private func put<T>(_ dict: inout [String: String], _ field: StatusField, _ value: T?) {
    guard let value else { return }
    dict[field.rawValue] = String(describing: value)
  }

  /// Stores an optional Boolean value in a flattened field map.
  private func put(_ dict: inout [String: String], _ field: StatusField, _ value: Bool?) {
    guard let value else { return }
    dict[field.rawValue] = value ? "true" : "false"
  }

  /// Stores a string list in a flattened field map.
  private func put(_ dict: inout [String: String], _ field: StatusField, _ value: [String]) {
    dict[field.rawValue] = value.joined(separator: ",")
  }
}
