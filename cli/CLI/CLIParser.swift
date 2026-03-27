import Foundation
import WiFiSnitchShared

/// Holds the validated request and target socket path.
struct ParsedArguments {
  let request: String
  let socketPath: String
}

/// Represents CLI control-flow and user-facing parser errors.
enum AppError: Error {
  case showUsage
  case showVersion
  case message(String)
}

/// Parses command-line arguments into one validated request.
func parseArguments(_ arguments: [String]) throws -> ParsedArguments {
  var socketPath = defaultSocketPath()
  var commandArgs: [String] = []

  var index = 1
  while index < arguments.count {
    let arg = arguments[index]

    if isHelpFlag(arg) {
      throw AppError.showUsage
    }

    if isVersionFlag(arg) {
      throw AppError.showVersion
    }

    if arg == "--socket" || arg == "-s" {
      socketPath = try parseSocketPath(arguments, index: &index)
      index += 1
      continue
    }

    if arg.hasPrefix("--socket=") {
      socketPath = try parseInlineSocketPath(arg)
      index += 1
      continue
    }

    commandArgs = Array(arguments[index...])
    break
  }

  return ParsedArguments(request: try buildRequest(from: commandArgs), socketPath: socketPath)
}

/// Converts command arguments into one internal protocol request.
private func buildRequest(from args: [String]) throws -> String {
  guard let first = args.first else {
    return "ssid"
  }

  guard let command = commandSpec(named: first) else {
    throw AppError.message("unknown command: \(first)")
  }

  let commandArgs = try validatedCommandArgs(from: Array(args.dropFirst()), command: command)
  guard !commandArgs.isEmpty else {
    return command.request
  }

  return command.request + " " + commandArgs.joined(separator: " ")
}

/// Finds a command spec by CLI name.
private func commandSpec(named name: String) -> CommandSpec? {
  commandRegistry.first(where: { $0.name == name.lowercased() })
}

/// Returns whether an argument is a help flag.
private func isHelpFlag(_ arg: String) -> Bool {
  arg == "--help" || arg == "-h"
}

/// Returns whether an argument is a version flag.
private func isVersionFlag(_ arg: String) -> Bool {
  arg == "--version" || arg == "-v"
}

/// Parses the socket path that follows a socket flag.
private func parseSocketPath(_ arguments: [String], index: inout Int) throws -> String {
  index += 1
  guard index < arguments.count else {
    throw AppError.message("missing value for \(arguments[index - 1])")
  }

  let socketPath = arguments[index]
  guard !socketPath.isEmpty else {
    throw AppError.message("missing value for \(arguments[index - 1])")
  }

  return socketPath
}

/// Parses the socket path from an inline socket argument.
private func parseInlineSocketPath(_ arg: String) throws -> String {
  let socketPath = String(arg.dropFirst("--socket=".count))
  guard !socketPath.isEmpty else {
    throw AppError.message("missing value for --socket")
  }

  return socketPath
}

/// Validates command arguments and returns the request arguments unchanged.
private func validatedCommandArgs(from args: [String], command: CommandSpec) throws -> [String] {
  var optionArgs = args

  if command.requiresFieldSpec {
    guard let fieldSpec = optionArgs.first, !fieldSpec.isEmpty else {
      throw AppError.message("missing field for \(command.name)")
    }

    // The field spec stays in the request and is excluded from option validation.
    optionArgs.removeFirst()
  }

  for arg in optionArgs {
    switch arg {
    case "--format=json", "--format=lines":
      guard command.allowsFormat else {
        throw AppError.message("command does not accept format arguments")
      }

    case "--format=text":
      guard command.allowsFormat else {
        throw AppError.message("command does not accept format arguments")
      }

      guard command.allowsTextFormat else {
        throw AppError.message("text format is not supported by this command")
      }

    default:
      throw AppError.message("unknown argument: \(arg)")
    }
  }

  return args
}
