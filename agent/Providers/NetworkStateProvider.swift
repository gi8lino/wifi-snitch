import Foundation
import SystemConfiguration

/// Watches the dynamic store and caches native network state.
final class NetworkStateProvider {
  private static let dateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
  }()

  private let lock = NSLock()
  private var store: SCDynamicStore!
  private var source: CFRunLoopSource?

  private var cachedNetwork = NetworkPayload(
    generatedAt: NetworkStateProvider.dateFormatter.string(from: Date()),
    primaryInterface: nil,
    activeTunnelInterface: nil,
    activeTunnelInterfaces: [],
    primaryInterfaceIsTunnel: false,
    ipv4Address: nil,
    ipv6Address: nil,
    defaultGateway: nil,
    dnsServers: [],
    internetReachable: false,
    captivePortal: false
  )

  private var cachedDebug: [String: String] = [:]

  private let watchedPatterns: [CFString] = [
    "State:/Network/Global/IPv4" as CFString,
    "State:/Network/Global/IPv6" as CFString,
    "State:/Network/Global/DNS" as CFString,
    "State:/Network/Service/.*/IPv4" as CFString,
    "State:/Network/Service/.*/IPv6" as CFString,
  ]

  /// Creates the provider and starts listening for dynamic-store changes.
  init() {
    var context = SCDynamicStoreContext(
      version: 0,
      info: Unmanaged.passUnretained(self).toOpaque(),
      retain: nil,
      release: nil,
      copyDescription: nil
    )

    guard
      let createdStore = SCDynamicStoreCreate(
        nil,
        "wifisnitch" as CFString,
        Self.storeChanged,
        &context
      )
    else {
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

  /// Returns the current cached network snapshot.
  func currentNetwork() -> NetworkPayload {
    lock.lock()
    defer { lock.unlock() }
    return cachedNetwork
  }

  /// Returns the current cached debug info.
  func debugInfo() -> [String: String] {
    lock.lock()
    defer { lock.unlock() }
    return cachedDebug
  }

  /// Handles dynamic-store change callbacks.
  private static let storeChanged: SCDynamicStoreCallBack = { _, _, info in
    guard let info else { return }
    let provider = Unmanaged<NetworkStateProvider>.fromOpaque(info).takeUnretainedValue()
    provider.refreshSnapshot()
  }

  /// Refreshes all cached network state from the dynamic store.
  private func refreshSnapshot() {
    guard
      let raw = SCDynamicStoreCopyMultiple(
        store,
        nil,
        watchedPatterns as CFArray
      ) as? [String: Any]
    else {
      lock.lock()
      cachedNetwork = NetworkPayload(
        generatedAt: NetworkStateProvider.dateFormatter.string(from: Date()),
        primaryInterface: nil,
        activeTunnelInterface: nil,
        activeTunnelInterfaces: [],
        primaryInterfaceIsTunnel: false,
        ipv4Address: nil,
        ipv6Address: nil,
        defaultGateway: nil,
        dnsServers: [],
        internetReachable: false,
        captivePortal: false
      )
      cachedDebug = [:]
      lock.unlock()
      return
    }

    let snapshot = buildSnapshot(from: raw)

    lock.lock()
    cachedNetwork = snapshot.network
    cachedDebug = snapshot.debug
    lock.unlock()
  }

  /// Builds a normalized snapshot from raw dynamic-store values.
  private func buildSnapshot(from raw: [String: Any]) -> (
    network: NetworkPayload, debug: [String: String]
  ) {
    var allInterfaces: [String] = []

    let globalIPv4 = raw["State:/Network/Global/IPv4"] as? [String: Any]
    let globalIPv6 = raw["State:/Network/Global/IPv6"] as? [String: Any]
    let globalDNS = raw["State:/Network/Global/DNS"] as? [String: Any]

    let primaryInterface =
      (globalIPv4?["PrimaryInterface"] as? String).flatMap(nonEmpty)
      ?? (globalIPv6?["PrimaryInterface"] as? String).flatMap(nonEmpty)

    let primaryServiceID =
      (globalIPv4?["PrimaryService"] as? String).flatMap(nonEmpty)
      ?? (globalIPv6?["PrimaryService"] as? String).flatMap(nonEmpty)

    if let primaryInterface {
      allInterfaces.append(primaryInterface)
    }

    for (key, value) in raw {
      guard key.hasPrefix("State:/Network/Service/") else {
        continue
      }

      guard key.hasSuffix("/IPv4") || key.hasSuffix("/IPv6") else {
        continue
      }

      guard let ip = value as? [String: Any],
        let interface = (ip["InterfaceName"] as? String).flatMap(nonEmpty)
      else {
        continue
      }

      if !allInterfaces.contains(interface) {
        allInterfaces.append(interface)
      }
    }

    let tunnelInterfaces = allInterfaces.filter(isTunnelInterface)
    let primaryInterfaceIsTunnel = primaryInterface.map(isTunnelInterface) ?? false

    // Only surface an "active" tunnel when the primary interface itself is tunnel-like.
    let activeTunnelInterface = primaryInterfaceIsTunnel ? primaryInterface : nil

    let primaryIPv4 = primaryServiceID.flatMap {
      raw["State:/Network/Service/\($0)/IPv4"] as? [String: Any]
    }
    let primaryIPv6 = primaryServiceID.flatMap {
      raw["State:/Network/Service/\($0)/IPv6"] as? [String: Any]
    }

    let ipv4Address = firstString(in: primaryIPv4?["Addresses"])
    let ipv6Address = firstString(in: primaryIPv6?["Addresses"])
    let defaultGateway =
      (globalIPv4?["Router"] as? String).flatMap(nonEmpty)
      ?? (primaryIPv4?["Router"] as? String).flatMap(nonEmpty)

    let dnsServers = stringArray(in: globalDNS?["ServerAddresses"])
    let internetReachable = isInternetReachable()
    let captivePortal = !internetReachable && ipv4Address != nil && defaultGateway != nil

    let network = NetworkPayload(
      generatedAt: Self.dateFormatter.string(from: Date()),
      primaryInterface: primaryInterface,
      activeTunnelInterface: activeTunnelInterface,
      activeTunnelInterfaces: tunnelInterfaces,
      primaryInterfaceIsTunnel: primaryInterfaceIsTunnel,
      ipv4Address: ipv4Address,
      ipv6Address: ipv6Address,
      defaultGateway: defaultGateway,
      dnsServers: dnsServers,
      internetReachable: internetReachable,
      captivePortal: captivePortal
    )

    let debug: [String: String] = [
      "network_interfaces": allInterfaces.joined(separator: ","),
      "network_tunnel_interfaces": tunnelInterfaces.joined(separator: ","),
      "network_ipv4_address": ipv4Address ?? "",
      "network_ipv6_address": ipv6Address ?? "",
      "network_default_gateway": defaultGateway ?? "",
      "network_dns_servers": dnsServers.joined(separator: ","),
      "network_internet_reachable": internetReachable ? "true" : "false",
      "network_captive_portal": captivePortal ? "true" : "false",
      "network_primary_interface_is_tunnel": primaryInterfaceIsTunnel ? "true" : "false",
    ]

    return (network, debug)
  }

  /// Returns whether an interface name looks like a tunnel.
  private func isTunnelInterface(_ name: String) -> Bool {
    name.hasPrefix("utun")
      || name.hasPrefix("ppp")
      || name.hasPrefix("ipsec")
      || name.hasPrefix("tap")
      || name.hasPrefix("tun")
  }

  /// Returns whether the network looks internet-reachable without doing an active probe.
  private func isInternetReachable() -> Bool {
    guard let reachability = SCNetworkReachabilityCreateWithName(nil, "1.1.1.1") else {
      return false
    }

    var flags = SCNetworkReachabilityFlags()
    guard SCNetworkReachabilityGetFlags(reachability, &flags) else {
      return false
    }

    return flags.contains(.reachable) && !flags.contains(.connectionRequired)
  }

  /// Returns the first trimmed string from an array-like value.
  private func firstString(in value: Any?) -> String? {
    guard let values = value as? [String] else { return nil }
    return values.first.flatMap(nonEmpty)
  }

  /// Returns a cleaned string array from an array-like value.
  private func stringArray(in value: Any?) -> [String] {
    guard let values = value as? [String] else { return [] }
    return values.compactMap(nonEmpty)
  }

  /// Returns a trimmed string or nil for empty input.
  private func nonEmpty(_ value: String) -> String? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}
