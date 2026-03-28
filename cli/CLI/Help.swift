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
    description: "Show the wifisnitchctl version"
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

  /// Returns the inline `--flag=value` payload when present.
  static func inlineValue(for option: CLIOption, argument: String) -> String? {
    let prefix = "\(option.flag)="
    guard argument.hasPrefix(prefix) else { return nil }
    return String(argument.dropFirst(prefix.count))
  }

  /// Prints one plain error line.
  static func printError(_ message: String) {
    fputs("wifisnitchctl: \(message)\n", stderr)
  }

  /// Prints one plain version line.
  static func printVersion() {
    fputs("wifisnitchctl \(BuildInfo.appVersion)\n", stdout)
  }

  /// Prints the command-line help text.
  static func printUsage() {
    let usageLines =
      commandRegistry
      .map(\.usageLine)
      .joined(separator: "\n")

    let commandDescriptions =
      commandRegistry
      .map { formatOption($0.name, $0.help) }
      .joined(separator: "\n")

    let exampleLines =
      (["wifisnitchctl"]
      + commandRegistry.compactMap(\.example)
      + [
        "wifisnitchctl field wifi.ssid,wifi.bssid,wifi.channel --format=lines",
        "wifisnitchctl field wifi.snr,wifi.link_quality --format=lines",
        "wifisnitchctl field network.primary_interface,network.active_tunnel_interface --format=lines",
        "wifisnitchctl field network.active_tunnel_interfaces --format=lines",
      ]).map { "  \($0)" }
      .joined(separator: "\n")

    let fieldLines = statusFieldRegistry
      .map { formatOption($0.name, $0.help) }
      .joined(separator: "\n")

    let help = """
      wifisnitchctl

      usage:
        wifisnitchctl [options]
      \(usageLines)

      commands:
      \(commandDescriptions)

      examples:
      \(exampleLines)

      fields:
      \(fieldLines)

      options:
      \(appOptions.map { formatOption(optionText(for: $0), $0.description) }.joined(separator: "\n"))

      environment:
      \(formatOption("WIFISNITCH_SOCKET", "Override socket path"))

      default socket:
        \(defaultSocketPath())
      """

    fputs(help + "\n", stderr)
  }
}
