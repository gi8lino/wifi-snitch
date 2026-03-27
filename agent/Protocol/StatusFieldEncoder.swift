import Foundation

/// Encodes status payloads into protocol responses.
struct StatusFieldEncoder {
  let availableFields = [
    "wifi.ssid",
    "wifi.bssid",
    "wifi.interface",
    "wifi.hardware_address",
    "wifi.power",
    "wifi.service_active",
    "wifi.rssi",
    "wifi.noise",
    "wifi.snr",
    "wifi.link_quality",
    "wifi.tx_rate",
    "wifi.channel",
    "wifi.channel_band",
    "wifi.channel_width",
    "wifi.security",
    "wifi.phy_mode",
    "wifi.interface_mode",
    "wifi.country_code",
    "wifi.roaming",
    "wifi.ssid_changed_at",
    "wifi.interface_changed_at",

    "network.primary_interface",
    "network.active_tunnel_interface",
    "network.active_tunnel_interfaces",
    "network.primary_interface_is_tunnel",
    "network.ipv4_address",
    "network.ipv6_address",
    "network.default_gateway",
    "network.dns_servers",
    "network.internet_reachable",
    "network.captive_portal",

    "auth.location_authorized",
    "auth.location_permission_state",
  ]

  /// Flattens the status payload into dot-separated fields.
  func flatten(_ payload: StatusPayload) -> [String: String] {
    var result: [String: String] = [:]

    put(&result, "wifi.ssid", payload.wifi.ssid)
    put(&result, "wifi.bssid", payload.wifi.bssid)
    put(&result, "wifi.interface", payload.wifi.interface)
    put(&result, "wifi.hardware_address", payload.wifi.hardwareAddress)
    put(&result, "wifi.power", payload.wifi.power)
    put(&result, "wifi.service_active", payload.wifi.serviceActive)
    put(&result, "wifi.rssi", payload.wifi.rssi)
    put(&result, "wifi.noise", payload.wifi.noise)
    put(&result, "wifi.snr", payload.wifi.snr)
    put(&result, "wifi.link_quality", payload.wifi.linkQuality)
    put(&result, "wifi.tx_rate", payload.wifi.txRate)
    put(&result, "wifi.channel", payload.wifi.channel)
    put(&result, "wifi.channel_band", payload.wifi.channelBand)
    put(&result, "wifi.channel_width", payload.wifi.channelWidth)
    put(&result, "wifi.security", payload.wifi.security)
    put(&result, "wifi.phy_mode", payload.wifi.phyMode)
    put(&result, "wifi.interface_mode", payload.wifi.interfaceMode)
    put(&result, "wifi.country_code", payload.wifi.countryCode)
    put(&result, "wifi.roaming", payload.wifi.roaming)
    put(&result, "wifi.ssid_changed_at", payload.wifi.ssidChangedAt)
    put(&result, "wifi.interface_changed_at", payload.wifi.interfaceChangedAt)

    put(&result, "network.primary_interface", payload.network.primaryInterface)
    put(&result, "network.active_tunnel_interface", payload.network.activeTunnelInterface)
    put(&result, "network.active_tunnel_interfaces", payload.network.activeTunnelInterfaces)
    put(&result, "network.primary_interface_is_tunnel", payload.network.primaryInterfaceIsTunnel)
    put(&result, "network.ipv4_address", payload.network.ipv4Address)
    put(&result, "network.ipv6_address", payload.network.ipv6Address)
    put(&result, "network.default_gateway", payload.network.defaultGateway)
    put(&result, "network.dns_servers", payload.network.dnsServers)
    put(&result, "network.internet_reachable", payload.network.internetReachable)
    put(&result, "network.captive_portal", payload.network.captivePortal)

    put(&result, "auth.location_authorized", payload.auth.locationAuthorized)
    put(&result, "auth.location_permission_state", payload.auth.locationPermissionState)

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
  func encodeFields(_ payload: StatusPayload, fields: [String], format: ResponseFormat) -> String {
    let flat = flatten(payload)

    for field in fields where !availableFields.contains(field) {
      return "ERR unknown_field \(field)"
    }

    switch format {
    case .text:
      guard fields.count == 1 else {
        return "ERR text_requires_single_field"
      }
      return flat[fields[0]] ?? "EMPTY"

    case .lines:
      return fields.map { "\($0)=\(flat[$0] ?? "")" }.joined(separator: "\n")

    case .json:
      var dict: [String: String] = [:]

      for field in fields {
        if let value = flat[field] {
          dict[field] = value
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
  private func put<T>(_ dict: inout [String: String], _ key: String, _ value: T?) {
    guard let value else { return }
    dict[key] = String(describing: value)
  }

  /// Stores an optional Boolean value in a flattened field map.
  private func put(_ dict: inout [String: String], _ key: String, _ value: Bool?) {
    guard let value else { return }
    dict[key] = value ? "true" : "false"
  }

  /// Stores a string list in a flattened field map.
  private func put(_ dict: inout [String: String], _ key: String, _ value: [String]) {
    dict[key] = value.joined(separator: ",")
  }
}
