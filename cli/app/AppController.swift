import Foundation

final class AppController {
  /// Parses arguments, sends the request, and returns the process exit code.
  func run() -> Int32 {
    guard let options = parseArgs() else {
      return 0
    }

    do {
      let reply = try SocketClient(socketPath: options.socketPath).send(request: options.request)
      print(reply, terminator: "")
      return 0
    } catch {
      return exitWithError(error)
    }
  }

  /// Prints an error and returns a failure code.
  private func exitWithError(_ error: Error) -> Int32 {
    fputs("\(error)\n", stderr)
    return 1
  }
}
