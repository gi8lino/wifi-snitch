import Foundation

struct CommandSpec {
  let name: String
  let request: String
  let help: String
  let allowsFormat: Bool
  let allowsTextFormat: Bool
  let requiresFieldSpec: Bool
  let example: String?

  /// Returns the generated usage suffix for this command.
  var usageSuffix: String {
    var parts: [String] = []

    if requiresFieldSpec {
      parts.append("<field>[,<field>...]")
    }

    if allowsFormat {
      let formatValues = allowsTextFormat ? "text|json|lines" : "json|lines"
      parts.append("[--format=\(formatValues)]")
    }

    return parts.joined(separator: " ")
  }

  /// Returns the generated usage line for this command.
  var usageLine: String {
    let suffix = usageSuffix
    guard !suffix.isEmpty else {
      return "  wifisnitchctl \(name)"
    }

    return "  wifisnitchctl \(name) \(suffix)"
  }
}

let commandRegistry: [CommandSpec] = [
  .init(
    name: "ssid", request: "ssid", help: "Print the current SSID", allowsFormat: false,
    allowsTextFormat: false, requiresFieldSpec: false, example: "wifisnitchctl ssid"),
  .init(
    name: "status", request: "status", help: "Print full status", allowsFormat: true,
    allowsTextFormat: false, requiresFieldSpec: false,
    example: "wifisnitchctl status --format=lines"),
  .init(
    name: "wifi", request: "wifi", help: "Print Wi-Fi payload", allowsFormat: false,
    allowsTextFormat: false, requiresFieldSpec: false, example: nil),
  .init(
    name: "network", request: "network", help: "Print network payload", allowsFormat: false,
    allowsTextFormat: false, requiresFieldSpec: false, example: nil),
  .init(
    name: "auth", request: "auth", help: "Print auth payload", allowsFormat: false,
    allowsTextFormat: false, requiresFieldSpec: false, example: nil),
  .init(
    name: "signal", request: "signal", help: "Print signal payload", allowsFormat: false,
    allowsTextFormat: false, requiresFieldSpec: false, example: nil),
  .init(
    name: "debug", request: "debug", help: "Print debug payload", allowsFormat: false,
    allowsTextFormat: false, requiresFieldSpec: false, example: nil),
  .init(
    name: "ping", request: "ping", help: "Check if the agent is alive", allowsFormat: false,
    allowsTextFormat: false, requiresFieldSpec: false, example: nil),
  .init(
    name: "version", request: "version", help: "Print protocol and app version",
    allowsFormat: false, allowsTextFormat: false, requiresFieldSpec: false, example: nil),
  .init(
    name: "fields", request: "fields", help: "List supported fields", allowsFormat: false,
    allowsTextFormat: false, requiresFieldSpec: false, example: nil),
  .init(
    name: "formats", request: "formats", help: "List supported formats", allowsFormat: false,
    allowsTextFormat: false, requiresFieldSpec: false, example: nil),
  .init(
    name: "field", request: "field", help: "Print selected fields", allowsFormat: true,
    allowsTextFormat: true, requiresFieldSpec: true,
    example: "wifisnitchctl field network.primary_interface_is_tunnel --format=text"),
]
