import Foundation

/// Supported output formats for status responses.
public enum ResponseFormat: String, Codable {
  case text
  case json
  case lines
}

/// Supported WiFiSnitch agent commands.
public enum StatusCommand: String, Codable, CaseIterable {
  case ping
  case version
  case fields
  case formats
  case ssid
  case status
  case wifi
  case network
  case auth
  case signal
  case debug
  case field
}

/// Supported WiFiSnitch field keys.
///
/// This enum is the single source of truth for field names used by the
/// protocol, CLI help, and agent-side field validation.
public enum StatusField: String, Codable, CaseIterable {
  case networkGeneratedAt = "network.generated_at"
  case wifiSSID = "wifi.ssid"
  case wifiBSSID = "wifi.bssid"
  case wifiInterface = "wifi.interface"
  case wifiHardwareAddress = "wifi.hardware_address"
  case wifiPower = "wifi.power"
  case wifiServiceActive = "wifi.service_active"
  case wifiRSSI = "wifi.rssi"
  case wifiNoise = "wifi.noise"
  case wifiSNR = "wifi.snr"
  case wifiLinkQuality = "wifi.link_quality"
  case wifiTxRate = "wifi.tx_rate"
  case wifiChannel = "wifi.channel"
  case wifiChannelBand = "wifi.channel_band"
  case wifiChannelWidth = "wifi.channel_width"
  case wifiSecurity = "wifi.security"
  case wifiPhyMode = "wifi.phy_mode"
  case wifiInterfaceMode = "wifi.interface_mode"
  case wifiCountryCode = "wifi.country_code"
  case wifiRoaming = "wifi.roaming"
  case wifiSSIDChangedAt = "wifi.ssid_changed_at"
  case wifiInterfaceChangedAt = "wifi.interface_changed_at"

  case networkPrimaryInterface = "network.primary_interface"
  case networkActiveTunnelInterface = "network.active_tunnel_interface"
  case networkActiveTunnelInterfaces = "network.active_tunnel_interfaces"
  case networkPrimaryInterfaceIsTunnel = "network.primary_interface_is_tunnel"
  case networkIPv4Address = "network.ipv4_address"
  case networkIPv6Address = "network.ipv6_address"
  case networkDefaultGateway = "network.default_gateway"
  case networkDNSServers = "network.dns_servers"
  case networkInternetReachable = "network.internet_reachable"
  case networkCaptivePortal = "network.captive_portal"

  case authLocationAuthorized = "auth.location_authorized"
  case authLocationPermissionState = "auth.location_permission_state"
}

/// Describes one protocol field shared by the agent and CLI.
public struct StatusFieldSpec {
  public let field: StatusField
  public let help: String

  public init(field: StatusField, help: String) {
    self.field = field
    self.help = help
  }
}

/// Ordered protocol field metadata shared by the agent and CLI.
public let statusFieldRegistry: [StatusFieldSpec] = [
  .init(field: .networkGeneratedAt, help: "Snapshot generation time"),
  .init(field: .wifiSSID, help: "Current Wi-Fi network name"),
  .init(field: .wifiBSSID, help: "Current access point BSSID"),
  .init(field: .wifiInterface, help: "Wi-Fi interface name"),
  .init(field: .wifiHardwareAddress, help: "Wi-Fi hardware MAC address"),
  .init(field: .wifiPower, help: "Wi-Fi power state"),
  .init(field: .wifiServiceActive, help: "CoreWLAN service availability"),
  .init(field: .wifiRSSI, help: "Received signal strength"),
  .init(field: .wifiNoise, help: "Noise floor"),
  .init(field: .wifiSNR, help: "Signal-to-noise ratio"),
  .init(field: .wifiLinkQuality, help: "Derived link quality percent"),
  .init(field: .wifiTxRate, help: "Transmit rate in Mbps"),
  .init(field: .wifiChannel, help: "Current Wi-Fi channel"),
  .init(field: .wifiChannelBand, help: "Channel band label"),
  .init(field: .wifiChannelWidth, help: "Channel width label"),
  .init(field: .wifiSecurity, help: "Current security mode"),
  .init(field: .wifiPhyMode, help: "PHY mode label"),
  .init(field: .wifiInterfaceMode, help: "Interface mode label"),
  .init(field: .wifiCountryCode, help: "Current country code"),
  .init(field: .wifiRoaming, help: "Roaming state"),
  .init(field: .wifiSSIDChangedAt, help: "Last SSID change time"),
  .init(field: .wifiInterfaceChangedAt, help: "Last interface change time"),

  .init(field: .networkPrimaryInterface, help: "Primary network interface"),
  .init(field: .networkActiveTunnelInterface, help: "First active tunnel interface"),
  .init(field: .networkActiveTunnelInterfaces, help: "All active tunnel interfaces"),
  .init(
    field: .networkPrimaryInterfaceIsTunnel,
    help: "Whether the primary interface is a tunnel"
  ),
  .init(field: .networkIPv4Address, help: "Primary IPv4 address"),
  .init(field: .networkIPv6Address, help: "Primary IPv6 address"),
  .init(field: .networkDefaultGateway, help: "Default gateway address"),
  .init(field: .networkDNSServers, help: "Configured DNS servers"),
  .init(field: .networkInternetReachable, help: "Internet reachability state"),
  .init(field: .networkCaptivePortal, help: "Captive portal state"),

  .init(field: .authLocationAuthorized, help: "Location authorization state"),
  .init(field: .authLocationPermissionState, help: "Location permission label"),
]

/// Describes one shared command.
public struct StatusCommandSpec {
  public let command: StatusCommand
  public let help: String
  public let allowsFormat: Bool
  public let allowsTextFormat: Bool
  public let requiresFieldSpec: Bool
  public let example: String?

  public init(
    command: StatusCommand,
    help: String,
    allowsFormat: Bool,
    allowsTextFormat: Bool,
    requiresFieldSpec: Bool,
    example: String? = nil
  ) {
    self.command = command
    self.help = help
    self.allowsFormat = allowsFormat
    self.allowsTextFormat = allowsTextFormat
    self.requiresFieldSpec = requiresFieldSpec
    self.example = example
  }
}

/// Ordered command metadata shared by the agent and CLI.
public let statusCommandRegistry: [StatusCommandSpec] = [
  .init(
    command: .ssid,
    help: "Print the current SSID",
    allowsFormat: false,
    allowsTextFormat: false,
    requiresFieldSpec: false,
    example: "wifisnitchctl ssid"
  ),
  .init(
    command: .status,
    help: "Print full status",
    allowsFormat: true,
    allowsTextFormat: false,
    requiresFieldSpec: false,
    example: "wifisnitchctl status --format=lines"
  ),
  .init(
    command: .wifi,
    help: "Print Wi-Fi payload",
    allowsFormat: false,
    allowsTextFormat: false,
    requiresFieldSpec: false
  ),
  .init(
    command: .network,
    help: "Print network payload",
    allowsFormat: false,
    allowsTextFormat: false,
    requiresFieldSpec: false
  ),
  .init(
    command: .auth,
    help: "Print auth payload",
    allowsFormat: false,
    allowsTextFormat: false,
    requiresFieldSpec: false
  ),
  .init(
    command: .signal,
    help: "Print signal payload",
    allowsFormat: false,
    allowsTextFormat: false,
    requiresFieldSpec: false
  ),
  .init(
    command: .debug,
    help: "Print debug payload",
    allowsFormat: false,
    allowsTextFormat: false,
    requiresFieldSpec: false
  ),
  .init(
    command: .ping,
    help: "Check if the agent is alive",
    allowsFormat: false,
    allowsTextFormat: false,
    requiresFieldSpec: false
  ),
  .init(
    command: .version,
    help: "Print protocol and app version",
    allowsFormat: false,
    allowsTextFormat: false,
    requiresFieldSpec: false
  ),
  .init(
    command: .fields,
    help: "List supported fields",
    allowsFormat: false,
    allowsTextFormat: false,
    requiresFieldSpec: false
  ),
  .init(
    command: .formats,
    help: "List supported formats",
    allowsFormat: false,
    allowsTextFormat: false,
    requiresFieldSpec: false
  ),
  .init(
    command: .field,
    help: "Print selected fields",
    allowsFormat: true,
    allowsTextFormat: true,
    requiresFieldSpec: true,
    example: "wifisnitchctl field network.primary_interface_is_tunnel --format=text"
  ),
]

/// Returns the shared spec for one command.
public func statusCommandSpec(for command: StatusCommand) -> StatusCommandSpec? {
  statusCommandRegistry.first(where: { $0.command == command })
}

/// Returns the shared spec for one CLI command name.
public func statusCommandSpec(named name: String) -> StatusCommandSpec? {
  guard let command = StatusCommand(rawValue: name.lowercased()) else { return nil }
  return statusCommandSpec(for: command)
}

/// Returns the generated usage suffix for one command.
public func statusCommandUsageSuffix(for spec: StatusCommandSpec) -> String {
  var parts: [String] = []

  if spec.requiresFieldSpec {
    parts.append("<field>[,<field>...]")
  }

  if spec.allowsFormat {
    let formatValues = spec.allowsTextFormat ? "text|json|lines" : "json|lines"
    parts.append("[--format=\(formatValues)]")
  }

  return parts.joined(separator: " ")
}

/// Returns the generated usage line for one command.
public func statusCommandUsageLine(for spec: StatusCommandSpec) -> String {
  let suffix = statusCommandUsageSuffix(for: spec)

  guard !suffix.isEmpty else {
    return "  wifisnitchctl \(spec.command.rawValue)"
  }

  return "  wifisnitchctl \(spec.command.rawValue) \(suffix)"
}

/// One structured request sent from the CLI to the agent.
public struct StatusAgentRequest: Codable {
  public let command: StatusCommand
  public let fields: [StatusField]
  public let format: ResponseFormat?

  public init(
    command: StatusCommand,
    fields: [StatusField] = [],
    format: ResponseFormat? = nil
  ) {
    self.command = command
    self.fields = fields
    self.format = format
  }
}

/// One structured response sent from the agent back to the CLI.
public struct StatusAgentResponse: Codable {
  public let body: String

  public init(body: String) {
    self.body = body
  }
}
