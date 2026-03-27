import Foundation
import WiFiSnitchShared

struct CLIOptions {
  let socketPath: String
  let request: String
}

/// Parses command-line arguments into CLI options.
///
/// Returns nil after printing help.
func parseArgs() -> CLIOptions? {
  var args = Array(CommandLine.arguments.dropFirst())
  var socketPath = defaultSocketPath()

  if args.contains("--help") || args.contains("-h") {
    printHelp()
    return nil
  }

  var index = 0
  while index < args.count {
    if args[index] == "--socket" {
      guard index + 1 < args.count else {
        fail("missing value for --socket")
      }

      socketPath = args[index + 1]
      args.removeSubrange(index...(index + 1))
      continue
    }

    index += 1
  }

  let request = buildRequest(from: args)
  return CLIOptions(socketPath: socketPath, request: request)
}

/// Converts CLI arguments into an internal protocol request.
func buildRequest(from args: [String]) -> String {
  guard let first = args.first else {
    return "ssid"
  }

  guard let command = commandSpec(named: first) else {
    fail("unknown command: \(first)")
  }

  let rest = Array(args.dropFirst())
  let commandArgs = validatedCommandArgs(from: rest, command: command)

  guard !commandArgs.isEmpty else {
    return command.request
  }

  return command.request + " " + commandArgs.joined(separator: " ")
}

/// Finds a command spec by CLI name.
func commandSpec(named name: String) -> CommandSpec? {
  commandRegistry.first(where: { $0.name == name.lowercased() })
}

/// Validates command arguments and returns the request arguments unchanged.
func validatedCommandArgs(from args: [String], command: CommandSpec) -> [String] {
  var optionArgs = args

  if command.requiresFieldSpec {
    guard let fieldSpec = optionArgs.first, !fieldSpec.isEmpty else {
      fail("missing field for \(command.name)")
    }

    // The field spec stays in the protocol request and is excluded from option validation.
    optionArgs.removeFirst()
  }

  for arg in optionArgs {
    switch arg {
    case "--format=json", "--format=lines":
      guard command.allowsFormat else {
        fail("command does not accept format arguments")
      }

    case "--format=text":
      guard command.allowsFormat else {
        fail("command does not accept format arguments")
      }

      guard command.allowsTextFormat else {
        fail("text format is not supported by this command")
      }

    default:
      fail("unknown argument: \(arg)")
    }
  }

  return args
}

/// Prints an error and exits.
func fail(_ message: String) -> Never {
  fputs("\(message)\n", stderr)
  exit(1)
}
