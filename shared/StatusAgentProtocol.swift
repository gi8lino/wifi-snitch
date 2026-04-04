import EasyBarShared
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

/// Shared field key used by the WiFiSnitch protocol.
public typealias StatusField = NetworkAgentField

/// Shared field metadata used by the WiFiSnitch protocol.
public typealias StatusFieldSpec = NetworkAgentFieldSpec

/// Ordered field metadata shared by the agent and CLI.
public let statusFieldRegistry = networkAgentFieldRegistry

/// Compatibility aliases that preserve existing WiFiSnitch field references.
public extension NetworkAgentField {
  static let networkGeneratedAt = Self.generatedAt
  static let wifiSSID = Self.ssid
  static let wifiBSSID = Self.bssid
  static let wifiInterface = Self.interfaceName
  static let wifiHardwareAddress = Self.hardwareAddress
  static let wifiPower = Self.power
  static let wifiServiceActive = Self.serviceActive
  static let wifiRSSI = Self.rssi
  static let wifiNoise = Self.noise
  static let wifiSNR = Self.snr
  static let wifiLinkQuality = Self.linkQuality
  static let wifiTxRate = Self.txRate
  static let wifiChannel = Self.channel
  static let wifiChannelBand = Self.channelBand
  static let wifiChannelWidth = Self.channelWidth
  static let wifiSecurity = Self.security
  static let wifiPhyMode = Self.phyMode
  static let wifiInterfaceMode = Self.interfaceMode
  static let wifiCountryCode = Self.countryCode
  static let wifiRoaming = Self.roaming
  static let wifiSSIDChangedAt = Self.ssidChangedAt
  static let wifiInterfaceChangedAt = Self.interfaceChangedAt
  static let networkPrimaryInterface = Self.primaryInterface
  static let networkActiveTunnelInterface = Self.activeTunnelInterface
  static let networkActiveTunnelInterfaces = Self.activeTunnelInterfaces
  static let networkPrimaryInterfaceIsTunnel = Self.primaryInterfaceIsTunnel
  static let networkIPv4Address = Self.ipv4Address
  static let networkIPv6Address = Self.ipv6Address
  static let networkDefaultGateway = Self.defaultGateway
  static let networkDNSServers = Self.dnsServers
  static let networkInternetReachable = Self.internetReachable
  static let networkCaptivePortal = Self.captivePortal
  static let authLocationAuthorized = Self.locationAuthorized
  static let authLocationPermissionState = Self.locationPermissionState
}

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
