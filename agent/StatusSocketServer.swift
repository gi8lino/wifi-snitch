import CoreLocation
import Foundation
import Darwin

final class StatusSocketServer {
    private let socketPath: String
    private var authorizationStatus: CLAuthorizationStatus
    private var serverFD: Int32 = -1

    private let protocolVersion = "1"
    private let appVersion = "1.0.0"

    private let wifiProvider = WiFiProvider()
    private let networkServiceProvider = NetworkServiceProvider()

    private let availableFields = [
        "wifi.ssid",
        "wifi.interface",
        "wifi.power",
        "wifi.rssi",
        "wifi.noise",
        "wifi.tx_rate",

        "network.primary_interface",
        "network.active_tunnel_interface",
        "network.active_tunnel_interfaces",

        "services.connected",
        "services.names",
        "services.connected_names",
        "services.connected_interfaces",

        "auth.location_authorized",
    ]

    /// Creates a server for the given socket path and authorization state.
    init(socketPath: String, authorizationStatus: CLAuthorizationStatus) {
        self.socketPath = socketPath
        self.authorizationStatus = authorizationStatus
    }

    /// Updates the cached authorization status.
    func setAuthorizationStatus(_ status: CLAuthorizationStatus) {
        authorizationStatus = status
    }

    /// Starts listening on the Unix domain socket.
    func start() {
        let socketURL = URL(fileURLWithPath: socketPath)
        let socketDir = socketURL.deletingLastPathComponent()

        try? FileManager.default.createDirectory(at: socketDir, withIntermediateDirectories: true)
        unlink(socketPath)

        serverFD = socket(AF_UNIX, SOCK_STREAM, 0)
        guard serverFD >= 0 else { return }

        var addr = makeSockAddrUn(path: socketPath)
        let addrLen = socklen_t(MemoryLayout<sockaddr_un>.size)

        let bindResult = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(serverFD, $0, addrLen)
            }
        }

        guard bindResult == 0 else {
            close(serverFD)
            serverFD = -1
            return
        }

        chmod(socketPath, mode_t(0o600))

        guard listen(serverFD, 8) == 0 else {
            close(serverFD)
            serverFD = -1
            return
        }

        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.acceptLoop()
        }
    }

    /// Accepts client connections until the process exits.
    private func acceptLoop() {
        while true {
            let clientFD = accept(serverFD, nil, nil)
            if clientFD >= 0 {
                handleClient(clientFD)
            }
        }
    }

    /// Handles one client request and writes the response.
    private func handleClient(_ clientFD: Int32) {
        defer { close(clientFD) }

        var buffer = [UInt8](repeating: 0, count: 4096)
        let n = read(clientFD, &buffer, buffer.count)
        if n <= 0 { return }

        let request = String(decoding: buffer.prefix(n), as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let response = handleRequest(request)
        sendAll(clientFD, Data((response + "\n").utf8))
    }

    /// Parses and handles a single protocol request.
    private func handleRequest(_ request: String) -> String {
        let trimmed = request.trimmingCharacters(in: .whitespacesAndNewlines)
        let upper = trimmed.uppercased()

        if upper == "PING" {
            return "PONG"
        }

        if upper == "VERSION" {
            return encodeJSON([
                "app_version": appVersion,
                "protocol_version": protocolVersion,
            ])
        }

        if upper == "FIELDS" {
            return availableFields.joined(separator: "\n")
        }

        if upper == "FORMATS" {
            return "text\njson\nlines"
        }

        if upper == "GET_DEBUG" {
            return encodeJSON(debugStatus())
        }

        let wifi = wifiProvider.currentWiFi()
        let network = networkServiceProvider.currentNetwork()
        let services = networkServiceProvider.currentServices()
        let auth = AuthPayload(
            locationAuthorized: isLocationAuthorized(authorizationStatus)
        )

        let payload = StatusPayload(
            wifi: wifi,
            network: network,
            auth: auth
        )

        if upper == "GET_SSID" {
            return payload.wifi.ssid.map { "OK \($0)" } ?? "EMPTY"
        }

        if upper == "GET_STATUS" {
            return encodeStatus(payload, format: .json)
        }

        if upper == "GET_WIFI" {
            return encodeJSON(payload.wifi)
        }

        if upper == "GET_NETWORK" {
            return encodeJSON(payload.network)
        }

        if upper == "GET_SERVICES" {
            return encodeJSON(services)
        }

        if upper == "GET_AUTH" {
            return encodeJSON(payload.auth)
        }

        if upper == "GET_SIGNAL" {
            return encodeJSON(SignalPayload(
                rssi: payload.wifi.rssi,
                noise: payload.wifi.noise,
                txRate: payload.wifi.txRate
            ))
        }

        let components = trimmed.split(separator: " ").map(String.init)
        guard !components.isEmpty else {
            return "ERR empty_request"
        }

        guard components[0].uppercased() == "GET" else {
            return "ERR unknown_command"
        }

        guard components.count >= 2 else {
            return "ERR missing_field"
        }

        let fieldSpec = components[1]
        let format = parseFormat(from: components.dropFirst(2))
        let fields = fieldSpec.split(separator: ",").map(String.init)

        return encodeSelectedFields(
            payload,
            services: services,
            fields: fields,
            format: format
        )
    }

    /// Returns raw debug information from the running app instance.
    private func debugStatus() -> [String: String] {
        let wifi = wifiProvider.currentWiFi()
        let network = networkServiceProvider.currentNetwork()
        let services = networkServiceProvider.currentServices()
        let networkDebug = networkServiceProvider.debugInfo()

        var result: [String: String] = [
            "socket_path": socketPath,
            "location_authorized": isLocationAuthorized(authorizationStatus) ? "true" : "false",
            "interface_name": String(describing: wifi.interface),
            "power": String(describing: wifi.power),
            "ssid_raw": String(describing: wifi.ssid),
            "rssi_raw": String(describing: wifi.rssi),
            "noise_raw": String(describing: wifi.noise),
            "tx_rate_raw": String(describing: wifi.txRate),
            "primary_interface": String(describing: network.primaryInterface),
            "active_tunnel_interface": String(describing: network.activeTunnelInterface),
            "active_tunnel_interfaces": network.activeTunnelInterfaces.joined(separator: ","),
            "services_connected": networkServiceProvider.hasConnectedServices(services) ? "true" : "false",
            "services_connected_names": services.filter(\.connected).map(\.name).joined(separator: ","),
            "services_names": services.map(\.name).joined(separator: ","),
        ]

        for (key, value) in networkDebug {
            result[key] = value
        }

        return result
    }

    /// Flattens the status payload into dot-separated keys.
    private func flattenedStatus(_ payload: StatusPayload, services: [ServicePayload]) -> [String: String] {
        var result: [String: String] = [:]

        put(&result, "wifi.ssid", payload.wifi.ssid)
        put(&result, "wifi.interface", payload.wifi.interface)
        put(&result, "wifi.power", payload.wifi.power)
        put(&result, "wifi.rssi", payload.wifi.rssi)
        put(&result, "wifi.noise", payload.wifi.noise)
        put(&result, "wifi.tx_rate", payload.wifi.txRate)

        put(&result, "network.primary_interface", payload.network.primaryInterface)
        put(&result, "network.active_tunnel_interface", payload.network.activeTunnelInterface)
        put(&result, "network.active_tunnel_interfaces", payload.network.activeTunnelInterfaces)

        put(&result, "services.connected", networkServiceProvider.hasConnectedServices(services))
        put(&result, "services.names", services.map(\.name))
        put(&result, "services.connected_names", services.filter(\.connected).map(\.name))
        put(&result, "services.connected_interfaces", services.filter(\.connected).compactMap(\.interface))

        put(&result, "auth.location_authorized", payload.auth.locationAuthorized)

        return result
    }

    /// Encodes selected fields in the requested format.
    private func encodeSelectedFields(
        _ payload: StatusPayload,
        services: [ServicePayload],
        fields: [String],
        format: ResponseFormat
    ) -> String {
        let flat = flattenedStatus(payload, services: services)

        for field in fields where !availableFields.contains(field) {
            return "ERR unknown_field \(field)"
        }

        switch format {
        case .text:
            guard fields.count == 1 else {
                return "ERR text_requires_single_field"
            }
            return flat[fields[0]] ?? "EMPTY"

        case .lines:
            return fields.map { "\($0)=\(flat[$0] ?? "")" }.joined(separator: "\n")

        case .json:
            var dict: [String: String] = [:]
            for field in fields {
                if let value = flat[field] {
                    dict[field] = value
                }
            }
            return encodeJSON(dict)
        }
    }

    /// Encodes the full status payload in the requested format.
    private func encodeStatus(_ payload: StatusPayload, format: ResponseFormat) -> String {
        switch format {
        case .json:
            return encodeJSON(payload)
        case .lines:
            let services = networkServiceProvider.currentServices()
            return flattenedStatus(payload, services: services)
                .sorted(by: { $0.key < $1.key })
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: "\n")
        case .text:
            return "ERR text_requires_single_field"
        }
    }

    /// Encodes an encodable value as JSON.
    private func encodeJSON<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        guard let data = try? encoder.encode(value),
              let text = String(data: data, encoding: .utf8) else {
            return "ERR encode_failed"
        }

        return text
    }

    /// Parses a response format from the request arguments.
    private func parseFormat<S: Sequence>(from args: S) -> ResponseFormat where S.Element == String {
        for arg in args {
            switch arg.lowercased() {
            case "--format=text":
                return .text
            case "--format=lines":
                return .lines
            case "--format=json":
                return .json
            default:
                continue
            }
        }
        return .json
    }

    /// Returns whether location access is authorized.
    private func isLocationAuthorized(_ status: CLAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }

    /// Writes all bytes in the response to the file descriptor.
    private func sendAll(_ fd: Int32, _ data: Data) {
        data.withUnsafeBytes { rawBuffer in
            guard let base = rawBuffer.baseAddress else { return }
            var sent = 0
            while sent < data.count {
                let n = write(fd, base.advanced(by: sent), data.count - sent)
                if n <= 0 { break }
                sent += n
            }
        }
    }

    /// Builds a Unix domain socket address for the given path.
    private func makeSockAddrUn(path: String) -> sockaddr_un {
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

    /// Stores an optional scalar value in the flattened map.
    private func put<T>(_ dict: inout [String: String], _ key: String, _ value: T?) {
        guard let value else { return }
        dict[key] = String(describing: value)
    }

    /// Stores an optional Boolean value in the flattened map.
    private func put(_ dict: inout [String: String], _ key: String, _ value: Bool?) {
        guard let value else { return }
        dict[key] = value ? "true" : "false"
    }

    /// Stores a string list in the flattened map.
    private func put(_ dict: inout [String: String], _ key: String, _ value: [String]) {
        dict[key] = value.joined(separator: ",")
    }
}
