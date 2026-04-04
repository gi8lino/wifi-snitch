import Foundation
import WiFiSnitchShared

struct StatusPayload: Encodable {
  let wifi: WiFiPayload
  let network: NetworkPayload
  let auth: AuthPayload

  /// Builds one payload from flattened field values.
  init(fieldValues: [String: StatusFieldValue]) {
    wifi = WiFiPayload(fieldValues: fieldValues)
    network = NetworkPayload(fieldValues: fieldValues)
    auth = AuthPayload(fieldValues: fieldValues)
  }
}

struct WiFiPayload: Encodable {
  let ssid: String?
  let bssid: String?
  let interface: String?
  let hardwareAddress: String?
  let power: Bool?
  let serviceActive: Bool?
  let rssi: Int?
  let noise: Int?
  let snr: Int?
  let linkQuality: Int?
  let txRate: Int?
  let channel: Int?
  let channelBand: String?
  let channelWidth: String?
  let security: String?
  let phyMode: String?
  let interfaceMode: String?
  let countryCode: String?
  let roaming: Bool
  let ssidChangedAt: String?
  let interfaceChangedAt: String?

  enum CodingKeys: String, CodingKey {
    case ssid
    case bssid
    case interface
    case hardwareAddress = "hardware_address"
    case power
    case serviceActive = "service_active"
    case rssi
    case noise
    case snr
    case linkQuality = "link_quality"
    case txRate = "tx_rate"
    case channel
    case channelBand = "channel_band"
    case channelWidth = "channel_width"
    case security
    case phyMode = "phy_mode"
    case interfaceMode = "interface_mode"
    case countryCode = "country_code"
    case roaming
    case ssidChangedAt = "ssid_changed_at"
    case interfaceChangedAt = "interface_changed_at"
  }

  /// Builds one Wi-Fi payload from flattened field values.
  init(fieldValues: [String: StatusFieldValue]) {
    ssid = fieldValues[StatusField.wifiSSID.rawValue]?.stringValue
    bssid = fieldValues[StatusField.wifiBSSID.rawValue]?.stringValue
    interface = fieldValues[StatusField.wifiInterface.rawValue]?.stringValue
    hardwareAddress = fieldValues[StatusField.wifiHardwareAddress.rawValue]?.stringValue
    power = fieldValues[StatusField.wifiPower.rawValue]?.boolValue
    serviceActive = fieldValues[StatusField.wifiServiceActive.rawValue]?.boolValue
    rssi = fieldValues[StatusField.wifiRSSI.rawValue]?.intValue
    noise = fieldValues[StatusField.wifiNoise.rawValue]?.intValue
    snr = fieldValues[StatusField.wifiSNR.rawValue]?.intValue
    linkQuality = fieldValues[StatusField.wifiLinkQuality.rawValue]?.intValue
    txRate = fieldValues[StatusField.wifiTxRate.rawValue]?.intValue
    channel = fieldValues[StatusField.wifiChannel.rawValue]?.intValue
    channelBand = fieldValues[StatusField.wifiChannelBand.rawValue]?.stringValue
    channelWidth = fieldValues[StatusField.wifiChannelWidth.rawValue]?.stringValue
    security = fieldValues[StatusField.wifiSecurity.rawValue]?.stringValue
    phyMode = fieldValues[StatusField.wifiPhyMode.rawValue]?.stringValue
    interfaceMode = fieldValues[StatusField.wifiInterfaceMode.rawValue]?.stringValue
    countryCode = fieldValues[StatusField.wifiCountryCode.rawValue]?.stringValue
    roaming = fieldValues[StatusField.wifiRoaming.rawValue]?.boolValue ?? false
    ssidChangedAt = fieldValues[StatusField.wifiSSIDChangedAt.rawValue]?.stringValue
    interfaceChangedAt = fieldValues[StatusField.wifiInterfaceChangedAt.rawValue]?.stringValue
  }
}

struct NetworkPayload: Encodable {
  let generatedAt: String
  let primaryInterface: String?
  let activeTunnelInterface: String?
  let activeTunnelInterfaces: [String]
  let primaryInterfaceIsTunnel: Bool
  let ipv4Address: String?
  let ipv6Address: String?
  let defaultGateway: String?
  let dnsServers: [String]
  let internetReachable: Bool
  let captivePortal: Bool

  enum CodingKeys: String, CodingKey {
    case generatedAt = "generated_at"
    case primaryInterface = "primary_interface"
    case activeTunnelInterface = "active_tunnel_interface"
    case activeTunnelInterfaces = "active_tunnel_interfaces"
    case primaryInterfaceIsTunnel = "primary_interface_is_tunnel"
    case ipv4Address = "ipv4_address"
    case ipv6Address = "ipv6_address"
    case defaultGateway = "default_gateway"
    case dnsServers = "dns_servers"
    case internetReachable = "internet_reachable"
    case captivePortal = "captive_portal"
  }

  /// Builds one network payload from flattened field values.
  init(fieldValues: [String: StatusFieldValue]) {
    generatedAt =
      fieldValues[StatusField.networkGeneratedAt.rawValue]?.stringValue
      ?? ISO8601DateFormatter().string(from: Date())
    primaryInterface = fieldValues[StatusField.networkPrimaryInterface.rawValue]?.stringValue
    activeTunnelInterface =
      fieldValues[StatusField.networkActiveTunnelInterface.rawValue]?.stringValue
    activeTunnelInterfaces =
      fieldValues[StatusField.networkActiveTunnelInterfaces.rawValue]?.stringListValue ?? []
    primaryInterfaceIsTunnel =
      fieldValues[StatusField.networkPrimaryInterfaceIsTunnel.rawValue]?.boolValue ?? false
    ipv4Address = fieldValues[StatusField.networkIPv4Address.rawValue]?.stringValue
    ipv6Address = fieldValues[StatusField.networkIPv6Address.rawValue]?.stringValue
    defaultGateway = fieldValues[StatusField.networkDefaultGateway.rawValue]?.stringValue
    dnsServers = fieldValues[StatusField.networkDNSServers.rawValue]?.stringListValue ?? []
    internetReachable =
      fieldValues[StatusField.networkInternetReachable.rawValue]?.boolValue ?? false
    captivePortal = fieldValues[StatusField.networkCaptivePortal.rawValue]?.boolValue ?? false
  }
}

struct AuthPayload: Encodable {
  let locationAuthorized: Bool
  let locationPermissionState: String

  enum CodingKeys: String, CodingKey {
    case locationAuthorized = "location_authorized"
    case locationPermissionState = "location_permission_state"
  }

  /// Builds one auth payload from flattened field values.
  init(fieldValues: [String: StatusFieldValue]) {
    locationAuthorized =
      fieldValues[StatusField.authLocationAuthorized.rawValue]?.boolValue ?? false
    locationPermissionState =
      fieldValues[StatusField.authLocationPermissionState.rawValue]?.stringValue ?? "unknown"
  }
}

struct SignalPayload: Encodable {
  let rssi: Int?
  let noise: Int?
  let snr: Int?
  let linkQuality: Int?
  let txRate: Int?

  enum CodingKeys: String, CodingKey {
    case rssi
    case noise
    case snr
    case linkQuality = "link_quality"
    case txRate = "tx_rate"
  }
}
