import EasyBarShared
import Foundation
import WiFiSnitchShared

struct CLIOption {
  let flag: String
  let short: String?
  let description: String
  let placeholder: String?

  init(
    flag: String,
    short: String? = nil,
    description: String,
    placeholder: String? = nil
  ) {
    self.flag = flag
    self.short = short
    self.description = description
    self.placeholder = placeholder
  }
}

enum ResponseFormat: String, CaseIterable {
  case text
  case json
  case lines
}

enum CLICommand: String, CaseIterable {
  case ping
  case version
  case fields
  case formats
  case fetch
}

struct CLICommandSpec {
  let command: CLICommand
  let help: String
  let allowsFormat: Bool
  let allowsTextFormat: Bool
  let requiresFieldSpec: Bool
  let example: String?

  init(
    command: CLICommand,
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

let commandRegistry: [CLICommandSpec] = [
  .init(
    command: .ping,
    help: "Check if the network agent is alive",
    allowsFormat: false,
    allowsTextFormat: false,
    requiresFieldSpec: false,
    example: "wifisnitch ping"
  ),
  .init(
    command: .version,
    help: "Print network-agent and protocol version",
    allowsFormat: false,
    allowsTextFormat: false,
    requiresFieldSpec: false,
    example: "wifisnitch version"
  ),
  .init(
    command: .fields,
    help: "List supported fetch fields",
    allowsFormat: false,
    allowsTextFormat: false,
    requiresFieldSpec: false,
    example: "wifisnitch fields"
  ),
  .init(
    command: .formats,
    help: "List supported fetch output formats",
    allowsFormat: false,
    allowsTextFormat: false,
    requiresFieldSpec: false,
    example: "wifisnitch formats"
  ),
  .init(
    command: .fetch,
    help: "Fetch selected fields or selectors from the agent",
    allowsFormat: true,
    allowsTextFormat: true,
    requiresFieldSpec: true,
    example: "wifisnitch fetch wifi.ssid,wifi.bssid,wifi.channel --format=lines"
  ),
]

func commandSpec(named name: String) -> CLICommandSpec? {
  guard let command = CLICommand(rawValue: name.lowercased()) else { return nil }
  return commandRegistry.first(where: { $0.command == command })
}

func commandUsageSuffix(for spec: CLICommandSpec) -> String {
  var parts: [String] = []

  if spec.requiresFieldSpec {
    parts.append("<field|selector>[,<field|selector>...]")
  }

  if spec.allowsFormat {
    let formatValues = spec.allowsTextFormat ? "text|json|lines" : "json|lines"
    parts.append("[--format=\(formatValues)]")
  }

  return parts.joined(separator: " ")
}

func commandUsageLine(for spec: CLICommandSpec) -> String {
  let suffix = commandUsageSuffix(for: spec)

  guard !suffix.isEmpty else {
    return "  wifisnitch \(spec.command.rawValue)"
  }

  return "  wifisnitch \(spec.command.rawValue) \(suffix)"
}

enum CLI {
  static let socketOption = CLIOption(
    flag: "--socket",
    short: "-s",
    description: "Override socket path",
    placeholder: "path"
  )
  static let versionOption = CLIOption(
    flag: "--version",
    short: "-v",
    description: "Show the wifisnitch version"
  )
  static let helpOption = CLIOption(
    flag: "--help",
    short: "-h",
    description: "Show this help"
  )

  static let appOptions: [CLIOption] = [
    socketOption,
    versionOption,
    helpOption,
  ]

  /// Formats one help row with aligned option text.
  static func formatOption(_ option: String, _ description: String) -> String {
    "  " + option.padding(toLength: 32, withPad: " ", startingAt: 0) + description
  }

  /// Returns the rendered text for one option, including short flag and placeholder.
  static func optionText(for option: CLIOption) -> String {
    var text = option.flag

    if let short = option.short {
      text += ", \(short)"
    }

    if let placeholder = option.placeholder {
      text += " <\(placeholder)>"
    }

    return text
  }

  /// Returns whether one argument matches an option's long or short flag.
  static func matches(_ option: CLIOption, argument: String) -> Bool {
    option.flag == argument || option.short == argument
  }

  /// Returns the inline `--flag=value` or `-f=value` payload when present.
  static func inlineValue(for option: CLIOption, argument: String) -> String? {
    let longPrefix = "\(option.flag)="
    if argument.hasPrefix(longPrefix) {
      return String(argument.dropFirst(longPrefix.count))
    }

    if let short = option.short {
      let shortPrefix = "\(short)="
      if argument.hasPrefix(shortPrefix) {
        return String(argument.dropFirst(shortPrefix.count))
      }
    }

    return nil
  }

  /// Prints one plain error line.
  static func printError(_ message: String) {
    fputs("wifisnitch: \(message)\n", stderr)
  }

  /// Prints one plain version line.
  static func printVersion() {
    fputs("wifisnitch \(WiFiSnitchShared.BuildInfo.appVersion)\n", stdout)
  }

  /// Prints the command-line help text.
  static func printUsage() {
    let usageLines =
      commandRegistry
      .map(commandUsageLine)
      .joined(separator: "\n")

    let commandDescriptions =
      commandRegistry
      .map { formatOption($0.command.rawValue, $0.help) }
      .joined(separator: "\n")

    let exampleLines =
      ([
        "wifisnitch ping",
        "wifisnitch version",
        "wifisnitch fields",
        "wifisnitch fetch wifi.ssid --format=text",
        "wifisnitch fetch wifi --format=json",
        "wifisnitch fetch all --format=json",
        "wifisnitch fetch wifi.ssid,wifi.bssid,wifi.channel --format=lines",
        "wifisnitch fetch network.primary_interface,network.active_tunnel_interface --format=lines",
        "wifisnitch fetch network.active_tunnel_interfaces --format=json",
      ]).map { "  \($0)" }
      .joined(separator: "\n")

    let selectorLines =
      ([
        formatOption("all", "Expand to every supported field")
      ]
      + networkAgentFieldNamespaceRegistry.map {
        formatOption($0.namespace.rawValue, $0.help)
      } + [
        formatOption("<namespace>.", "Alias for the bare namespace selector"),
        formatOption("<namespace>.*", "Alias for the bare namespace selector"),
      ])
      .joined(separator: "\n")

    let fieldLines =
      networkAgentFieldRegistry
      .map { formatOption($0.field.rawValue, $0.help) }
      .joined(separator: "\n")

    let help = """
      wifisnitch

      usage:
        wifisnitch [options]
      \(usageLines)

      commands:
      \(commandDescriptions)

      examples:
      \(exampleLines)

      fields:
      \(fieldLines)

      selectors:
      \(selectorLines)

      options:
      \(appOptions.map { formatOption(optionText(for: $0), $0.description) }.joined(separator: "\n"))

      environment:
      \(formatOption(WifiSnitchEnvironmentKeys.configPath, "Select the WiFiSnitch config file"))
      \(formatOption(WifiSnitchEnvironmentKeys.loggingLevel, "Temporarily override log verbosity"))

      active socket:
        \(WiFiSnitchRuntimeConfig.current.socketPath)
      """

    fputs(help + "\n", stderr)
  }
}
