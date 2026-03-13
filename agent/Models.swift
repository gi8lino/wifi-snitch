import Foundation

struct StatusPayload: Encodable {
    let wifi: WiFiPayload
    let network: NetworkPayload
    let auth: AuthPayload
}

struct WiFiPayload: Encodable {
    let ssid: String?
    let interface: String?
    let power: Bool?
    let rssi: Int?
    let noise: Int?
    let txRate: Int?

    enum CodingKeys: String, CodingKey {
        case ssid
        case interface
        case power
        case rssi
        case noise
        case txRate = "tx_rate"
    }
}

struct NetworkPayload: Encodable {
    let primaryInterface: String?
    let activeTunnelInterface: String?
    let activeTunnelInterfaces: [String]

    enum CodingKeys: String, CodingKey {
        case primaryInterface = "primary_interface"
        case activeTunnelInterface = "active_tunnel_interface"
        case activeTunnelInterfaces = "active_tunnel_interfaces"
    }
}

struct ServicePayload: Encodable {
    let name: String
    let status: String
    let connected: Bool
    let interface: String?
}

struct AuthPayload: Encodable {
    let locationAuthorized: Bool

    enum CodingKeys: String, CodingKey {
        case locationAuthorized = "location_authorized"
    }
}

struct SignalPayload: Encodable {
    let rssi: Int?
    let noise: Int?
    let txRate: Int?

    enum CodingKeys: String, CodingKey {
        case rssi
        case noise
        case txRate = "tx_rate"
    }
}

enum ResponseFormat {
    case text
    case json
    case lines
}
