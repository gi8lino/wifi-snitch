import Foundation

struct CommandSpec {
    let name: String
    let request: String
    let allowsFormat: Bool
    let help: String
}

let commandRegistry: [CommandSpec] = [
    .init(name: "ssid", request: "GET_SSID", allowsFormat: false, help: "Print the current SSID"),
    .init(name: "status", request: "GET_STATUS", allowsFormat: true, help: "Print full status"),
    .init(name: "wifi", request: "GET_WIFI", allowsFormat: false, help: "Print Wi-Fi payload"),
    .init(name: "network", request: "GET_NETWORK", allowsFormat: false, help: "Print network payload"),
    .init(name: "auth", request: "GET_AUTH", allowsFormat: false, help: "Print auth payload"),
    .init(name: "signal", request: "GET_SIGNAL", allowsFormat: false, help: "Print signal payload"),
    .init(name: "debug", request: "GET_DEBUG", allowsFormat: false, help: "Print debug payload"),
    .init(name: "ping", request: "PING", allowsFormat: false, help: "Check if the agent is alive"),
    .init(name: "version", request: "VERSION", allowsFormat: false, help: "Print protocol and app version"),
    .init(name: "fields", request: "FIELDS", allowsFormat: false, help: "List supported fields"),
    .init(name: "formats", request: "FORMATS", allowsFormat: false, help: "List supported formats"),
]
