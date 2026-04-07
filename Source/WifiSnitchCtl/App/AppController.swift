import EasyBarShared
import Foundation

final class AppController {
  private let renderer = NetworkAgentResponseRenderer()

  /// Runs the CLI command flow and returns the process exit code.
  func run() -> Int32 {
    do {
      let parsed = try parseArguments(CommandLine.arguments)
      try handle(parsed)
      return 0
    } catch AppError.showUsage {
      CLI.printUsage()
      return 1
    } catch AppError.showVersion {
      CLI.printVersion()
      return 0
    } catch AppError.message(let message) {
      CLI.printError(message)
    } catch {
      CLI.printError("\(error)")
    }

    return 1
  }

  /// Executes one parsed CLI operation.
  private func handle(_ parsed: ParsedArguments) throws {
    switch parsed.command {
    case .listFields:
      writeStdout(networkAgentFieldRegistry.map(\.field.rawValue).joined(separator: "\n"))

    case .listFormats:
      writeStdout(ResponseFormat.allCases.map(\.rawValue).joined(separator: "\n"))

    case .remote(let request, let output):
      let reply = try LineSocketClientTransport<NetworkAgentRequest, NetworkAgentMessage>(
        socketPath: parsed.socketPath
      ).send(request: request)

      let text = try renderer.renderReply(reply, output: output)
      writeStdout(text)
    }
  }

  /// Writes one text block to stdout with exactly one trailing newline.
  private func writeStdout(_ text: String) {
    let output = text.hasSuffix("\n") ? text : text + "\n"
    fputs(output, stdout)
  }
}
