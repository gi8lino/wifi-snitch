import EasyBarShared
import Foundation
import WiFiSnitchShared

struct ParsedArguments {
  let command: ParsedCommand
  let socketPath: String
}

enum ParsedCommand {
  case listFields
  case listFormats
  case remote(NetworkAgentRequest, RemoteOutput)
}

enum RemoteOutput {
  case ping
  case version
  case fetch(fields: [NetworkAgentField], format: ResponseFormat)
}

enum AppError: Error {
  case showUsage
  case showVersion
  case message(String)
}

/// Parses command-line arguments into one validated operation.
func parseArguments(_ arguments: [String]) throws -> ParsedArguments {
  var socketPath = WiFiSnitchRuntimeConfig.current.socketPath
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
    command: try buildCommand(from: commandArgs),
    socketPath: socketPath
  )
}

/// Converts CLI command arguments into one validated operation.
private func buildCommand(from args: [String]) throws -> ParsedCommand {
  guard let first = args.first else {
    throw AppError.showUsage
  }

  guard let spec = commandSpec(named: first) else {
    throw AppError.message("unknown command: \(first)")
  }

  let optionArgs = Array(args.dropFirst())

  switch spec.command {
  case .fields:
    guard optionArgs.isEmpty else {
      throw AppError.message("command does not accept arguments")
    }
    return .listFields

  case .formats:
    guard optionArgs.isEmpty else {
      throw AppError.message("command does not accept arguments")
    }
    return .listFormats

  case .ping:
    guard optionArgs.isEmpty else {
      throw AppError.message("command does not accept arguments")
    }
    return .remote(NetworkAgentRequest(command: .ping), .ping)

  case .version:
    guard optionArgs.isEmpty else {
      throw AppError.message("command does not accept arguments")
    }
    return .remote(NetworkAgentRequest(command: .version), .version)

  case .fetch:
    let parsed = try validatedFetchArgs(from: optionArgs, spec: spec)
    return .remote(
      NetworkAgentRequest(command: .fetch, fields: parsed.fields),
      .fetch(fields: parsed.fields, format: parsed.format)
    )
  }
}

private struct ValidatedFetchArgs {
  let fields: [NetworkAgentField]
  let format: ResponseFormat
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

/// Validates fetch arguments and returns the requested fields plus output format.
private func validatedFetchArgs(from args: [String], spec: CLICommandSpec) throws
  -> ValidatedFetchArgs
{
  var optionArgs = args

  guard let fieldSpec = optionArgs.first, !fieldSpec.isEmpty else {
    throw AppError.message("missing field for \(spec.command.rawValue)")
  }

  let selectors =
    fieldSpec
    .split(separator: ",")
    .map(String.init)
    .filter { !$0.isEmpty }

  let fields: [NetworkAgentField]
  do {
    fields = try expandNetworkAgentFieldSelectors(selectors)
  } catch let error as NetworkAgentFieldSelectorError {
    throw AppError.message(error.localizedDescription)
  }

  guard !fields.isEmpty else {
    throw AppError.message("missing field for \(spec.command.rawValue)")
  }

  optionArgs.removeFirst()

  var format: ResponseFormat = .json

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

  if format == .text, fields.count != 1 {
    throw AppError.message("text format requires exactly one field")
  }

  return ValidatedFetchArgs(
    fields: fields,
    format: format
  )
}
