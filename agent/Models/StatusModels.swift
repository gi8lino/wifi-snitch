import Foundation

struct StatusPayload: Encodable {
  let wifi: WiFiPayload
  let network: NetworkPayload
  let auth: AuthPayload
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
}

struct NetworkPayload: Encodable {
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
}

struct AuthPayload: Encodable {
  let locationAuthorized: Bool
  let locationPermissionState: String

  enum CodingKeys: String, CodingKey {
    case locationAuthorized = "location_authorized"
    case locationPermissionState = "location_permission_state"
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

enum ResponseFormat {
  case text
  case json
  case lines
}
