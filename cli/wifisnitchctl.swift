import Foundation
import Darwin

struct CLIOptions {
    let socketPath: String
    let request: String
}

/// Returns the default socket path used by WiFiSnitch.
func defaultSocketPath() -> String {
    if let override = ProcessInfo.processInfo.environment["WIFISNITCH_SOCKET"]?
        .trimmingCharacters(in: .whitespacesAndNewlines),
       !override.isEmpty {
        return override
    }

    let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    let dir = caches.appendingPathComponent("wifisnitch", isDirectory: true)
    return dir.appendingPathComponent("wifisnitch.sock").path
}

/// Prints the command-line help text.
func printHelp() {
    let help = """
    wifisnitchctl

    Usage:
      wifisnitchctl [options]
      wifisnitchctl ssid
      wifisnitchctl status [--format=json|lines]
      wifisnitchctl wifi
      wifisnitchctl network
      wifisnitchctl services
      wifisnitchctl auth
      wifisnitchctl signal
      wifisnitchctl debug
      wifisnitchctl ping
      wifisnitchctl version
      wifisnitchctl fields
      wifisnitchctl formats
      wifisnitchctl get <field>[,<field>...] [--format=text|json|lines]

    Examples:
      wifisnitchctl
      wifisnitchctl ssid
      wifisnitchctl status
      wifisnitchctl status --format=lines
      wifisnitchctl wifi
      wifisnitchctl network
      wifisnitchctl services
      wifisnitchctl auth
      wifisnitchctl signal
      wifisnitchctl get wifi.ssid --format=text
      wifisnitchctl get wifi.ssid,wifi.rssi,network.active_tunnel_interfaces --format=lines
      wifisnitchctl ping
      wifisnitchctl version
      wifisnitchctl fields
      wifisnitchctl formats
      wifisnitchctl debug

    Fields:
      wifi.ssid
      wifi.interface
      wifi.power
      wifi.rssi
      wifi.noise
      wifi.tx_rate
      network.primary_interface
      network.active_tunnel_interface
      network.active_tunnel_interfaces
      services.connected
      services.names
      services.connected_names
      services.connected_interfaces
      auth.location_authorized

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

/// Parses command-line arguments into CLI options.
///
/// Returns nil after printing help.
func parseArgs() -> CLIOptions? {
    var args = Array(CommandLine.arguments.dropFirst())
    var socketPath = defaultSocketPath()

    if args.contains("--help") || args.contains("-h") {
        printHelp()
        return nil
    }

    var index = 0
    while index < args.count {
        if args[index] == "--socket" {
            guard index + 1 < args.count else {
                fputs("missing value for --socket\n", stderr)
                exit(1)
            }

            socketPath = args[index + 1]
            args.removeSubrange(index...(index + 1))
            continue
        }

        index += 1
    }

    let request = makeRequest(from: args)
    return CLIOptions(socketPath: socketPath, request: request)
}

/// Converts CLI arguments into an internal protocol request.
func makeRequest(from args: [String]) -> String {
    guard let first = args.first else {
        return "GET_SSID"
    }

    let command = first.lowercased()
    let rest = Array(args.dropFirst())

    switch command {
    case "ssid":
        return "GET_SSID"
    case "status":
        return rest.isEmpty ? "GET_STATUS" : "GET_STATUS " + rest.joined(separator: " ")
    case "wifi":
        return "GET_WIFI"
    case "network":
        return "GET_NETWORK"
    case "services":
        return "GET_SERVICES"
    case "auth":
        return "GET_AUTH"
    case "signal":
        return "GET_SIGNAL"
    case "debug":
        return "GET_DEBUG"
    case "ping":
        return "PING"
    case "version":
        return "VERSION"
    case "fields":
        return "FIELDS"
    case "formats":
        return "FORMATS"
    case "get":
        guard !rest.isEmpty else {
            fputs("missing field for get\n", stderr)
            exit(1)
        }
        return "GET " + rest.joined(separator: " ")
    default:
        return args.joined(separator: " ")
    }
}

/// Builds a Unix domain socket address for the given path.
func makeSockAddrUn(path: String) -> sockaddr_un {
    var addr = sockaddr_un()
    addr.sun_family = sa_family_t(AF_UNIX)

    let bytes = Array(path.utf8)
    let maxLen = MemoryLayout.size(ofValue: addr.sun_path)

    withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
        ptr.withMemoryRebound(to: CChar.self, capacity: maxLen) { cptr in
            memset(cptr, 0, maxLen)
            for (index, byte) in bytes.prefix(maxLen - 1).enumerated() {
                cptr[index] = CChar(bitPattern: byte)
            }
        }
    }

    return addr
}

guard let options = parseArgs() else {
    exit(0)
}

let fd = socket(AF_UNIX, SOCK_STREAM, 0)
guard fd >= 0 else {
    fputs("socket failed\n", stderr)
    exit(1)
}

var addr = makeSockAddrUn(path: options.socketPath)
let addrLen = socklen_t(MemoryLayout<sockaddr_un>.size)

let connectResult = withUnsafePointer(to: &addr) {
    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        connect(fd, $0, addrLen)
    }
}

guard connectResult == 0 else {
    perror("connect")
    close(fd)
    exit(1)
}

let requestData = Data((options.request + "\n").utf8)
requestData.withUnsafeBytes { rawBuffer in
    guard let base = rawBuffer.baseAddress else { return }

    let written = write(fd, base, requestData.count)
    if written < 0 {
        perror("write")
        close(fd)
        exit(1)
    }
}

var buffer = [UInt8](repeating: 0, count: 16384)
let n = read(fd, &buffer, buffer.count)
close(fd)

guard n > 0 else {
    fputs("no reply\n", stderr)
    exit(1)
}

let reply = String(decoding: buffer.prefix(n), as: UTF8.self)
print(reply, terminator: "")
