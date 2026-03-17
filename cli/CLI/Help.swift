import Foundation
import WiFiSnitchShared

/// Prints the command-line help text.
func printHelp() {
    let commandLines = commandRegistry
        .map { "  wifisnitchctl \($0.name)" + ($0.allowsFormat ? " [--format=json|lines]" : "") }
        .joined(separator: "\n")

    let commandDescriptions = commandRegistry
        .map { "  \($0.name.padding(toLength: 10, withPad: " ", startingAt: 0)) \($0.help)" }
        .joined(separator: "\n")

    let help = """
    wifisnitchctl

    Usage:
      wifisnitchctl [options]
    \(commandLines)
      wifisnitchctl get <field>[,<field>...] [--format=text|json|lines]

    Commands:
    \(commandDescriptions)
      get        Print selected fields

    Examples:
      wifisnitchctl
      wifisnitchctl ssid
      wifisnitchctl status --format=lines
      wifisnitchctl get wifi.ssid,wifi.bssid,wifi.channel --format=lines
      wifisnitchctl get wifi.snr,wifi.link_quality --format=lines
      wifisnitchctl get network.primary_interface,network.active_tunnel_interface --format=lines
      wifisnitchctl get network.primary_interface_is_tunnel --format=text
      wifisnitchctl get network.active_tunnel_interfaces --format=lines

    Fields:
      wifi.ssid
      wifi.bssid
      wifi.interface
      wifi.power
      wifi.rssi
      wifi.noise
      wifi.snr
      wifi.link_quality
      wifi.tx_rate
      wifi.channel
      wifi.channel_band
      wifi.security
      wifi.phy_mode
      wifi.country_code
      wifi.roaming
      wifi.ssid_changed_at
      wifi.interface_changed_at
      network.primary_interface
      network.active_tunnel_interface
      network.active_tunnel_interfaces
      network.primary_interface_is_tunnel
      network.ipv4_address
      network.ipv6_address
      network.default_gateway
      network.dns_servers
      network.internet_reachable
      network.captive_portal
      auth.location_authorized
      auth.location_permission_state

    Options:
      --socket PATH   Override the socket path
      --help          Show this help

    Environment:
      WIFISNITCH_SOCKET   Override the socket path

    Default socket:
      \(defaultSocketPath())
    """

    print(help)
}
