import EasyBarNetworkAgentCore
import Foundation
import WiFiSnitchShared

final class AppController {
  private let snapshotProvider = NetworkSnapshotProvider(refreshIntervalSeconds: 0)
  private let encoder = StatusFieldEncoder()

  private lazy var requestHandler = StatusRequestHandler(
    snapshotProvider: snapshotProvider,
    encoder: encoder
  )

  private var server: StatusAgentServer?

  /// Starts the snapshot provider and socket server.
  func start() {
    snapshotProvider.start {}

    server = StatusAgentServer(
      socketPath: defaultSocketPath(),
      handleRequest: { [weak self] request in
        guard let self else {
          return StatusAgentResponse(body: "ERR server_unavailable")
        }

        return self.requestHandler.handle(request: request)
      }
    )

    server?.start()
  }

  /// Stops the socket server and snapshot provider.
  func stop() {
    server?.stop()
    server = nil
    snapshotProvider.stop()
  }
}
