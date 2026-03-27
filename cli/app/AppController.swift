import Foundation

final class AppController {
  /// Runs the CLI command flow and returns the process exit code.
  func run() -> Int32 {
    do {
      let parsed = try parseArguments(CommandLine.arguments)
      try sendCommand(parsed)
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

    CLI.printUsage()
    return 1
  }

  /// Sends one request to the socket and prints the reply.
  private func sendCommand(_ parsed: ParsedArguments) throws {
    let reply = try SocketClient(socketPath: parsed.socketPath).send(request: parsed.request)
    print(reply, terminator: "")
  }
}
