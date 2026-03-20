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
        return "GET_SSID"
    }

    if first.lowercased() == "get" {
        let rest = Array(args.dropFirst())
        guard let fieldSpec = rest.first, !fieldSpec.isEmpty else {
            fail("missing field for get")
        }

        validateArgs(Array(rest.dropFirst()), command: getCommand)
        return "GET " + rest.joined(separator: " ")
    }

    guard let command = commandRegistry.first(where: { $0.name == first.lowercased() }) else {
        fail("unknown command: \(first)")
    }

    let rest = Array(args.dropFirst())
    validateArgs(rest, command: command)

    if rest.isEmpty {
        return command.request
    }

    return command.request + " " + rest.joined(separator: " ")
}

/// Validates optional request arguments.
func validateArgs(_ args: [String], command: CommandSpec) {
    for arg in args {
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
}

/// Prints an error and exits.
func fail(_ message: String) -> Never {
    fputs("\(message)\n", stderr)
    exit(1)
}
