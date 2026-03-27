import Foundation
import WiFiSnitchShared

enum CLI {
  /// Formats one help row with aligned option text.
  static func formatOption(_ option: String, _ description: String) -> String {
    "  " + option.padding(toLength: 32, withPad: " ", startingAt: 0) + description
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
      \(formatOption("--socket, -s <path>", "Override socket path"))
      \(formatOption("--version, -v", "Show the wifisnitchctl version"))
      \(formatOption("--help, -h", "Show this help"))

      environment:
      \(formatOption("WIFISNITCH_SOCKET", "Override socket path"))

      default socket:
        \(defaultSocketPath())
      """

    fputs(help + "\n", stderr)
  }
}
