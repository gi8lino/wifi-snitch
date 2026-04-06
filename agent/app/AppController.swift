import EasyBarNetworkAgentCore
import EasyBarShared
import Foundation
import WiFiSnitchShared

final class AppController {
  private let logger: ProcessLogger
  private let snapshotProvider: NetworkSnapshotProvider
  private let encoder = StatusFieldEncoder()

  private lazy var requestHandler = StatusRequestHandler(
    snapshotProvider: snapshotProvider,
    encoder: encoder
  )

  private var server: StatusAgentServer?

  /// Creates one app controller with the logger used by the app and shared network core.
  init(logger: ProcessLogger) {
    self.logger = logger
    snapshotProvider = NetworkSnapshotProvider(
      refreshIntervalSeconds: 0,
      logger: logger
    )
  }

  /// Starts the snapshot provider and socket server.
  func start() -> Bool {
    snapshotProvider.start {}

    server = StatusAgentServer(
      socketPath: defaultWifiSnitchSocketPath(),
      handleRequest: { [weak self] request in
        guard let self else {
          return StatusAgentResponse(body: "ERR server_unavailable")
        }

        return self.requestHandler.handle(request: request)
      }
    )

    server?.start()
    return true
  }

  /// Stops the socket server and snapshot provider.
  func stop() {
    server?.stop()
    server = nil
    snapshotProvider.stop()
  }
}
