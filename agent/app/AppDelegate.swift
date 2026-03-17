import Cocoa

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let controller = AppController()

    /// Starts the agent when the app finishes launching.
    func applicationDidFinishLaunching(_ notification: Notification) {
        controller.start()
    }

    /// Stops the agent before the app terminates.
    func applicationWillTerminate(_ notification: Notification) {
        controller.stop()
    }
}
