import Darwin
import Foundation

/// The CLI entry point.
@main
enum WifiSnitchCtlApp {
  /// Runs the CLI process.
  static func main() {
    let controller = AppController()
    exit(controller.run())
  }
}
