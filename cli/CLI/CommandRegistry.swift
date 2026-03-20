import Foundation

struct CommandSpec {
    let name: String
    let request: String
    let help: String
    let allowsFormat: Bool
    let allowsTextFormat: Bool
    let example: String?

    /// Returns the generated usage suffix for this command.
    var usageSuffix: String {
        guard allowsFormat else {
            return ""
        }

        let formatValues = allowsTextFormat ? "text|json|lines" : "json|lines"
        return "[--format=\(formatValues)]"
    }

    /// Returns the generated usage line for this command.
    var usageLine: String {
        let suffix = usageSuffix
        return suffix.isEmpty ? "  wifisnitchctl \(name)" : "  wifisnitchctl \(name) \(suffix)"
    }
}

let commandRegistry: [CommandSpec] = [
    .init(name: "ssid", request: "GET_SSID", help: "Print the current SSID", allowsFormat: false, allowsTextFormat: false, example: "wifisnitchctl ssid"),
    .init(name: "status", request: "GET_STATUS", help: "Print full status", allowsFormat: true, allowsTextFormat: false, example: "wifisnitchctl status --format=lines"),
    .init(name: "wifi", request: "GET_WIFI", help: "Print Wi-Fi payload", allowsFormat: false, allowsTextFormat: false, example: nil),
    .init(name: "network", request: "GET_NETWORK", help: "Print network payload", allowsFormat: false, allowsTextFormat: false, example: nil),
    .init(name: "auth", request: "GET_AUTH", help: "Print auth payload", allowsFormat: false, allowsTextFormat: false, example: nil),
    .init(name: "signal", request: "GET_SIGNAL", help: "Print signal payload", allowsFormat: false, allowsTextFormat: false, example: nil),
    .init(name: "debug", request: "GET_DEBUG", help: "Print debug payload", allowsFormat: false, allowsTextFormat: false, example: nil),
    .init(name: "ping", request: "PING", help: "Check if the agent is alive", allowsFormat: false, allowsTextFormat: false, example: nil),
    .init(name: "version", request: "VERSION", help: "Print protocol and app version", allowsFormat: false, allowsTextFormat: false, example: nil),
    .init(name: "fields", request: "FIELDS", help: "List supported fields", allowsFormat: false, allowsTextFormat: false, example: nil),
    .init(name: "formats", request: "FORMATS", help: "List supported formats", allowsFormat: false, allowsTextFormat: false, example: nil),
]

let getCommand = CommandSpec(
    name: "get <field>[,<field>...]",
    request: "GET",
    help: "Print selected fields",
    allowsFormat: true,
    allowsTextFormat: true,
    example: "wifisnitchctl get network.primary_interface_is_tunnel --format=text"
)
