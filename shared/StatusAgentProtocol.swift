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
extension NetworkAgentField {
  public static let networkGeneratedAt = Self.generatedAt
  public static let wifiSSID = Self.ssid
  public static let wifiBSSID = Self.bssid
  public static let wifiInterface = Self.interfaceName
  public static let wifiHardwareAddress = Self.hardwareAddress
  public static let wifiPower = Self.power
  public static let wifiServiceActive = Self.serviceActive
  public static let wifiRSSI = Self.rssi
  public static let wifiNoise = Self.noise
  public static let wifiSNR = Self.snr
  public static let wifiLinkQuality = Self.linkQuality
  public static let wifiTxRate = Self.txRate
  public static let wifiChannel = Self.channel
  public static let wifiChannelBand = Self.channelBand
  public static let wifiChannelWidth = Self.channelWidth
  public static let wifiSecurity = Self.security
  public static let wifiPhyMode = Self.phyMode
  public static let wifiInterfaceMode = Self.interfaceMode
  public static let wifiCountryCode = Self.countryCode
  public static let wifiRoaming = Self.roaming
  public static let wifiSSIDChangedAt = Self.ssidChangedAt
  public static let wifiInterfaceChangedAt = Self.interfaceChangedAt
  public static let networkPrimaryInterface = Self.primaryInterface
  public static let networkActiveTunnelInterface = Self.activeTunnelInterface
  public static let networkActiveTunnelInterfaces = Self.activeTunnelInterfaces
  public static let networkPrimaryInterfaceIsTunnel = Self.primaryInterfaceIsTunnel
  public static let networkIPv4Address = Self.ipv4Address
  public static let networkIPv6Address = Self.ipv6Address
  public static let networkDefaultGateway = Self.defaultGateway
  public static let networkDNSServers = Self.dnsServers
  public static let networkInternetReachable = Self.internetReachable
  public static let networkCaptivePortal = Self.captivePortal
  public static let authLocationAuthorized = Self.locationAuthorized
  public static let authLocationPermissionState = Self.locationPermissionState
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
