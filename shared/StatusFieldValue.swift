import Foundation

/// One typed field value returned by the WiFiSnitch agent.
public enum StatusFieldValue: Codable, Equatable {
  case string(String)
  case bool(Bool)
  case int(Int)
  case stringList([String])

  /// Returns the string representation used by text and line output.
  public var rendered: String {
    switch self {
    case .string(let value):
      return value
    case .bool(let value):
      return value ? "true" : "false"
    case .int(let value):
      return String(value)
    case .stringList(let value):
      return value.joined(separator: ",")
    }
  }

  /// Decodes one field value from a plain JSON scalar or string array.
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if let value = try? container.decode(Bool.self) {
      self = .bool(value)
      return
    }

    if let value = try? container.decode(Int.self) {
      self = .int(value)
      return
    }

    if let value = try? container.decode([String].self) {
      self = .stringList(value)
      return
    }

    self = .string(try container.decode(String.self))
  }

  /// Encodes one field value as a plain JSON scalar or string array.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()

    switch self {
    case .string(let value):
      try container.encode(value)
    case .bool(let value):
      try container.encode(value)
    case .int(let value):
      try container.encode(value)
    case .stringList(let value):
      try container.encode(value)
    }
  }
}
