import EasyBarShared
import Foundation

/// Shared typed field value used by the WiFiSnitch agent.
public typealias StatusFieldValue = NetworkAgentFieldValue

public extension NetworkAgentFieldValue {
  /// Returns the string representation used by text and line output.
  var rendered: String {
    switch self {
    case .string(let value):
      return value
    case .bool(let value):
      return value ? "true" : "false"
    case .int(let value):
      return String(value)
    case .double(let value):
      return String(value)
    case .stringList(let value):
      return value.joined(separator: ",")
    }
  }
}
