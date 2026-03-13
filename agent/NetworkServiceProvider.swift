import Foundation
import SystemConfiguration

/// Collects live interface and service state from the dynamic store and serves a cached snapshot.
final class NetworkServiceProvider {
    private let stateQueue = DispatchQueue(label: "wifisnitch.network-service-provider")
    private var store: SCDynamicStore!
    private var source: CFRunLoopSource?

    private var cachedNetwork = NetworkPayload(
        primaryInterface: nil,
        activeTunnelInterface: nil,
        activeTunnelInterfaces: []
    )

    private var cachedServices: [ServicePayload] = []
    private var cachedDebug: [String: String] = [:]

    private let watchedPatterns: [CFString] = [
        "State:/Network/Global/IPv4" as CFString,
        "State:/Network/Global/IPv6" as CFString,
        "State:/Network/Service/.*/IPv4" as CFString,
        "State:/Network/Service/.*/IPv6" as CFString,
        "State:/Network/Service/.*/PPP" as CFString,
        "State:/Network/Service/.*/IPSec" as CFString,
        "Setup:/Network/Service/.*" as CFString,
    ]

    /// Creates the provider and starts watching the dynamic store for changes.
    init() {
        var context = SCDynamicStoreContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        guard let createdStore = SCDynamicStoreCreate(
            nil,
            "wifisnitch" as CFString,
            Self.storeChanged,
            &context
        ) else {
            fatalError("failed to create SCDynamicStore")
        }

        store = createdStore
        SCDynamicStoreSetNotificationKeys(store, nil, watchedPatterns as CFArray)

        if let createdSource = SCDynamicStoreCreateRunLoopSource(nil, store, 0) {
            source = createdSource
            CFRunLoopAddSource(CFRunLoopGetMain(), createdSource, .commonModes)
        }

        refreshSnapshot()
    }

    deinit {
        if let source {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
    }

    /// Returns the current cached network payload.
    func currentNetwork() -> NetworkPayload {
        stateQueue.sync { cachedNetwork }
    }

    /// Returns the current cached live services.
    func currentServices() -> [ServicePayload] {
        stateQueue.sync { cachedServices }
    }

    /// Returns cached debug information.
    func debugInfo() -> [String: String] {
        stateQueue.sync { cachedDebug }
    }

    /// Returns whether any service is connected.
    func hasConnectedServices(_ services: [ServicePayload]) -> Bool {
        services.contains(where: \.connected)
    }

    /// Handles dynamic store change notifications.
    private static let storeChanged: SCDynamicStoreCallBack = { _, _, info in
        guard let info else { return }
        let provider = Unmanaged<NetworkServiceProvider>.fromOpaque(info).takeUnretainedValue()
        provider.refreshSnapshot()
    }

    /// Refreshes the cached snapshot from the dynamic store.
    private func refreshSnapshot() {
        guard let raw = SCDynamicStoreCopyMultiple(
            store,
            nil,
            watchedPatterns as CFArray
        ) as? [String: Any] else {
            stateQueue.sync {
                cachedNetwork = NetworkPayload(
                    primaryInterface: nil,
                    activeTunnelInterface: nil,
                    activeTunnelInterfaces: []
                )
                cachedServices = []
                cachedDebug = [:]
            }
            return
        }

        let snapshot = buildSnapshot(from: raw)

        stateQueue.sync {
            cachedNetwork = snapshot.network
            cachedServices = snapshot.services
            cachedDebug = snapshot.debug
        }
    }

    /// Builds a complete snapshot from raw dynamic-store values.
    private func buildSnapshot(from raw: [String: Any]) -> (network: NetworkPayload, services: [ServicePayload], debug: [String: String]) {
        var allInterfaces: [String] = []

        let globalIPv4 = raw["State:/Network/Global/IPv4"] as? [String: Any]
        let globalIPv6 = raw["State:/Network/Global/IPv6"] as? [String: Any]

        let primaryInterface =
            (globalIPv4?["PrimaryInterface"] as? String).flatMap(nonEmpty)
            ?? (globalIPv6?["PrimaryInterface"] as? String).flatMap(nonEmpty)

        if let primaryInterface {
            allInterfaces.append(primaryInterface)
        }

        var serviceIDs = Set<String>()

        for (key, value) in raw {
            guard key.hasPrefix("State:/Network/Service/") else {
                continue
            }

            if key.hasSuffix("/PPP") || key.hasSuffix("/IPSec") {
                if let serviceID = serviceID(fromStateKey: key) {
                    serviceIDs.insert(serviceID)
                }
                continue
            }

            guard key.hasSuffix("/IPv4") || key.hasSuffix("/IPv6") else {
                continue
            }

            guard let ip = value as? [String: Any],
                  let interface = (ip["InterfaceName"] as? String).flatMap(nonEmpty) else {
                continue
            }

            if !allInterfaces.contains(interface) {
                allInterfaces.append(interface)
            }

            if let serviceID = serviceID(fromStateKey: key), isTunnelInterface(interface) {
                serviceIDs.insert(serviceID)
            }
        }

        let tunnelInterfaces = allInterfaces.filter(isTunnelInterface)
        let activeTunnelInterface = primaryInterface.flatMap { isTunnelInterface($0) ? $0 : nil } ?? tunnelInterfaces.first

        var services: [ServicePayload] = []

        for serviceID in serviceIDs.sorted() {
            let setup = raw["Setup:/Network/Service/\(serviceID)"] as? [String: Any]
            let ipv4 = raw["State:/Network/Service/\(serviceID)/IPv4"] as? [String: Any]
            let ipv6 = raw["State:/Network/Service/\(serviceID)/IPv6"] as? [String: Any]
            let ppp = raw["State:/Network/Service/\(serviceID)/PPP"] as? [String: Any]
            let ipsec = raw["State:/Network/Service/\(serviceID)/IPSec"] as? [String: Any]

            let interface = extractInterfaceName(
                ipv4: ipv4,
                ipv6: ipv6,
                setup: setup
            ) ?? activeTunnelInterface

            let status = extractStatus(
                ppp: ppp,
                ipsec: ipsec,
                ipv4: ipv4,
                ipv6: ipv6,
                interface: interface
            )

            let connected = isConnected(status: status)

            services.append(ServicePayload(
                name: extractName(setup: setup, serviceID: serviceID, interface: interface),
                status: status,
                connected: connected,
                interface: connected ? interface : nil
            ))
        }

        services.sort { lhs, rhs in
            if lhs.connected != rhs.connected {
                return lhs.connected && !rhs.connected
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }

        let network = NetworkPayload(
            primaryInterface: primaryInterface,
            activeTunnelInterface: activeTunnelInterface,
            activeTunnelInterfaces: tunnelInterfaces
        )

        let debug: [String: String] = [
            "network_interfaces": allInterfaces.joined(separator: ","),
            "network_tunnel_interfaces": tunnelInterfaces.joined(separator: ","),
            "services_connected": hasConnectedServices(services) ? "true" : "false",
            "services_connected_names": services.filter(\.connected).map(\.name).joined(separator: ","),
            "services_names": services.map(\.name).joined(separator: ","),
        ]

        return (network, services, debug)
    }

    /// Extracts the service identifier from a state key.
    private func serviceID(fromStateKey key: String) -> String? {
        let prefix = "State:/Network/Service/"
        guard key.hasPrefix(prefix) else { return nil }

        let remainder = String(key.dropFirst(prefix.count))
        guard let slash = remainder.firstIndex(of: "/") else { return nil }

        let value = String(remainder[..<slash])
        return value.isEmpty ? nil : value
    }

    /// Extracts a readable service name.
    private func extractName(setup: [String: Any]?, serviceID: String, interface: String?) -> String {
        if let setup,
           let name = (setup["UserDefinedName"] as? String).flatMap(nonEmpty) {
            return name
        }

        if let interface, !interface.isEmpty {
            return interface
        }

        return serviceID
    }

    /// Extracts an interface name from live or setup data.
    private func extractInterfaceName(
        ipv4: [String: Any]?,
        ipv6: [String: Any]?,
        setup: [String: Any]?
    ) -> String? {
        if let ipv4,
           let interface = (ipv4["InterfaceName"] as? String).flatMap(nonEmpty) {
            return interface
        }

        if let ipv6,
           let interface = (ipv6["InterfaceName"] as? String).flatMap(nonEmpty) {
            return interface
        }

        if let setup,
           let interface = setup["Interface"] as? [String: Any],
           let deviceName = (interface["DeviceName"] as? String).flatMap(nonEmpty) {
            return deviceName
        }

        return nil
    }

    /// Extracts a normalized service status from live data.
    private func extractStatus(
        ppp: [String: Any]?,
        ipsec: [String: Any]?,
        ipv4: [String: Any]?,
        ipv6: [String: Any]?,
        interface: String?
    ) -> String {
        if let status = normalizedStatus(from: ppp) {
            return status
        }

        if let status = normalizedStatus(from: ipsec) {
            return status
        }

        if let interface, isTunnelInterface(interface), (ipv4 != nil || ipv6 != nil) {
            return "Connected"
        }

        return "Disconnected"
    }

    /// Extracts a normalized status from a PPP or IPSec dictionary.
    private func normalizedStatus(from dict: [String: Any]?) -> String? {
        guard let dict else { return nil }

        if let connected = dict["Connected"] as? Bool {
            return connected ? "Connected" : "Disconnected"
        }

        if let status = dict["Status"] as? Int {
            switch status {
            case 0:
                return "Disconnected"
            case 1:
                return "Connecting"
            case 2:
                return "Connected"
            case 3:
                return "Disconnecting"
            default:
                break
            }
        }

        return nil
    }

    /// Returns whether a normalized status means active.
    private func isConnected(status: String) -> Bool {
        status == "Connected" || status == "Connecting"
    }

    /// Returns whether an interface name looks like a tunnel.
    private func isTunnelInterface(_ name: String) -> Bool {
        name.hasPrefix("utun")
            || name.hasPrefix("ppp")
            || name.hasPrefix("ipsec")
            || name.hasPrefix("tap")
            || name.hasPrefix("tun")
    }

    /// Returns a trimmed string or nil for empty input.
    private func nonEmpty(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
