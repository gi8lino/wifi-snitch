import EasyBarShared
import Foundation

struct NetworkAgentResponseRenderer {
  /// Renders one structured network-agent reply for terminal output.
  func renderReply(_ reply: NetworkAgentMessage, output: RemoteOutput) throws -> String {
    if reply.kind == .error {
      throw AppError.message(reply.message ?? "unknown error")
    }

    switch output {
    case .ping:
      guard reply.kind == .pong else {
        throw AppError.message("unexpected response: \(reply.kind.rawValue)")
      }
      return "PONG"

    case .version:
      guard reply.kind == .version, let version = reply.version else {
        throw AppError.message("unexpected response: \(reply.kind.rawValue)")
      }
      return encodeJSON(version)

    case .fetch(let fields, let format):
      guard reply.kind == .fields else {
        throw AppError.message("unexpected response: \(reply.kind.rawValue)")
      }
      return renderFetchedFields(
        requestedFields: fields,
        values: reply.fields ?? [:],
        format: format
      )
    }
  }

  /// Renders fetched fields in the requested output format.
  private func renderFetchedFields(
    requestedFields: [NetworkAgentField],
    values: [String: NetworkAgentFieldValue],
    format: ResponseFormat
  ) -> String {
    switch format {
    case .text:
      guard let field = requestedFields.first else {
        return ""
      }
      return rendered(values[field.rawValue])

    case .lines:
      return
        requestedFields
        .map { "\($0.rawValue)=\(rendered(values[$0.rawValue]))" }
        .joined(separator: "\n")

    case .json:
      var filtered: [String: NetworkAgentFieldValue] = [:]

      for field in requestedFields {
        if let value = values[field.rawValue] {
          filtered[field.rawValue] = value
        }
      }

      return encodeJSON(filtered)
    }
  }

  /// Encodes one value as sorted JSON text.
  private func encodeJSON<T: Encodable>(_ value: T) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]

    guard let data = try? encoder.encode(value),
      let text = String(data: data, encoding: .utf8)
    else {
      return "{}"
    }

    return text
  }

  /// Returns the terminal representation of one typed field value.
  private func rendered(_ value: NetworkAgentFieldValue?) -> String {
    guard let value else { return "" }

    switch value {
    case .string(let string):
      return string
    case .bool(let bool):
      return bool ? "true" : "false"
    case .int(let int):
      return String(int)
    case .double(let double):
      return String(double)
    case .stringList(let strings):
      return strings.joined(separator: ",")
    }
  }
}
