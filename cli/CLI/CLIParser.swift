import Foundation
import WiFiSnitchShared

/// Holds the validated request and target socket path.
struct ParsedArguments {
  let request: StatusAgentRequest
  let socketPath: String
}

/// Represents CLI control-flow and user-facing parser errors.
enum AppError: Error {
  case showUsage
  case showVersion
  case message(String)
}

/// Parses command-line arguments into one validated structured request.
func parseArguments(_ arguments: [String]) throws -> ParsedArguments {
  var socketPath = defaultSocketPath()
  var commandArgs: [String] = []

  var index = 1
  while index < arguments.count {
    let arg = arguments[index]

    if CLI.matches(CLI.helpOption, argument: arg) {
      throw AppError.showUsage
    }

    if CLI.matches(CLI.versionOption, argument: arg) {
      throw AppError.showVersion
    }

    if let value = CLI.inlineValue(for: CLI.socketOption, argument: arg) {
      socketPath = try validatedSocketPath(value, flag: CLI.socketOption.flag)
      index += 1
      continue
    }

    if CLI.matches(CLI.socketOption, argument: arg) {
      socketPath = try parseSocketPath(arguments, index: &index, flag: arg)
      index += 1
      continue
    }

    commandArgs = Array(arguments[index...])
    break
  }

  return ParsedArguments(
    request: try buildRequest(from: commandArgs),
    socketPath: socketPath
  )
}

/// Converts CLI command arguments into one structured internal request.
private func buildRequest(from args: [String]) throws -> StatusAgentRequest {
  guard let first = args.first else {
    return StatusAgentRequest(command: .ssid)
  }

  guard let spec = statusCommandSpec(named: first) else {
    throw AppError.message("unknown command: \(first)")
  }

  let validated = try validatedCommandArgs(from: Array(args.dropFirst()), spec: spec)

  return StatusAgentRequest(
    command: validated.command,
    fields: validated.fields,
    format: validated.format
  )
}

private struct ValidatedRequestParts {
  let command: StatusCommand
  let fields: [StatusField]
  let format: ResponseFormat?
}

/// Parses the socket path that follows a socket flag.
private func parseSocketPath(_ arguments: [String], index: inout Int, flag: String) throws -> String
{
  index += 1
  guard index < arguments.count else {
    throw AppError.message("missing value for \(flag)")
  }

  return try validatedSocketPath(arguments[index], flag: flag)
}

/// Ensures one parsed socket path is present and non-empty.
private func validatedSocketPath(_ socketPath: String, flag: String) throws -> String {
  guard !socketPath.isEmpty else {
    throw AppError.message("missing value for \(flag)")
  }

  return socketPath
}

/// Validates command arguments and returns structured request parts.
private func validatedCommandArgs(from args: [String], spec: StatusCommandSpec) throws
  -> ValidatedRequestParts
{
  var optionArgs = args
  var fields: [StatusField] = []
  var format: ResponseFormat?

  if spec.requiresFieldSpec {
    guard let fieldSpec = optionArgs.first, !fieldSpec.isEmpty else {
      throw AppError.message("missing field for \(spec.command.rawValue)")
    }

    fields =
      try fieldSpec
      .split(separator: ",")
      .map(String.init)
      .filter { !$0.isEmpty }
      .map { raw in
        guard let field = StatusField(rawValue: raw) else {
          throw AppError.message("unknown field: \(raw)")
        }
        return field
      }

    guard !fields.isEmpty else {
      throw AppError.message("missing field for \(spec.command.rawValue)")
    }

    optionArgs.removeFirst()
  }

  for arg in optionArgs {
    switch arg {
    case "--format=json":
      guard spec.allowsFormat else {
        throw AppError.message("command does not accept format arguments")
      }
      format = .json

    case "--format=lines":
      guard spec.allowsFormat else {
        throw AppError.message("command does not accept format arguments")
      }
      format = .lines

    case "--format=text":
      guard spec.allowsFormat else {
        throw AppError.message("command does not accept format arguments")
      }

      guard spec.allowsTextFormat else {
        throw AppError.message("text format is not supported by this command")
      }

      format = .text

    default:
      throw AppError.message("unknown argument: \(arg)")
    }
  }

  return ValidatedRequestParts(
    command: spec.command,
    fields: fields,
    format: format
  )
}
