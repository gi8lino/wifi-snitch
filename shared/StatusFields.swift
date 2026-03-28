import Foundation

/// Describes one protocol field shared by the agent and CLI.
public struct StatusFieldSpec {
  public let name: String
  public let help: String
}

/// Ordered protocol field metadata shared by the agent and CLI.
public let statusFieldRegistry: [StatusFieldSpec] = [
  .init(name: "wifi.ssid", help: "Current Wi-Fi network name"),
  .init(name: "wifi.bssid", help: "Current access point BSSID"),
  .init(name: "wifi.interface", help: "Wi-Fi interface name"),
  .init(name: "wifi.hardware_address", help: "Wi-Fi hardware MAC address"),
  .init(name: "wifi.power", help: "Wi-Fi power state"),
  .init(name: "wifi.service_active", help: "CoreWLAN service availability"),
  .init(name: "wifi.rssi", help: "Received signal strength"),
  .init(name: "wifi.noise", help: "Noise floor"),
  .init(name: "wifi.snr", help: "Signal-to-noise ratio"),
  .init(name: "wifi.link_quality", help: "Derived link quality percent"),
  .init(name: "wifi.tx_rate", help: "Transmit rate in Mbps"),
  .init(name: "wifi.channel", help: "Current Wi-Fi channel"),
  .init(name: "wifi.channel_band", help: "Channel band label"),
  .init(name: "wifi.channel_width", help: "Channel width label"),
  .init(name: "wifi.security", help: "Current security mode"),
  .init(name: "wifi.phy_mode", help: "PHY mode label"),
  .init(name: "wifi.interface_mode", help: "Interface mode label"),
  .init(name: "wifi.country_code", help: "Current country code"),
  .init(name: "wifi.roaming", help: "Roaming state"),
  .init(name: "wifi.ssid_changed_at", help: "Last SSID change time"),
  .init(name: "wifi.interface_changed_at", help: "Last interface change time"),

  .init(name: "network.primary_interface", help: "Primary network interface"),
  .init(name: "network.active_tunnel_interface", help: "First active tunnel interface"),
  .init(name: "network.active_tunnel_interfaces", help: "All active tunnel interfaces"),
  .init(
    name: "network.primary_interface_is_tunnel", help: "Whether the primary interface is a tunnel"),
  .init(name: "network.ipv4_address", help: "Primary IPv4 address"),
  .init(name: "network.ipv6_address", help: "Primary IPv6 address"),
  .init(name: "network.default_gateway", help: "Default gateway address"),
  .init(name: "network.dns_servers", help: "Configured DNS servers"),
  .init(name: "network.internet_reachable", help: "Internet reachability state"),
  .init(name: "network.captive_portal", help: "Captive portal state"),

  .init(name: "auth.location_authorized", help: "Location authorization state"),
  .init(name: "auth.location_permission_state", help: "Location permission label"),
]
