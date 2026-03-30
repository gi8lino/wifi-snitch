import Darwin
import EasyBarShared
import Foundation
import WiFiSnitchShared

/// Serves structured WiFiSnitch status requests over a Unix domain socket.
final class StatusAgentServer {
  private enum NoSubscriber {}

  private let transport:
    LineSocketServerTransport<
      NoSubscriber,
      StatusAgentRequest,
      StatusAgentResponse
    >
  private let handleRequest: (StatusAgentRequest) -> StatusAgentResponse

  /// Creates a new agent server for the given socket path.
  init(
    socketPath: String,
    handleRequest: @escaping (StatusAgentRequest) -> StatusAgentResponse
  ) {
    self.handleRequest = handleRequest
    transport = LineSocketServerTransport(
      socketPath: socketPath,
      serverLabel: "wifisnitch"
    )
  }

  /// Starts accepting requests.
  func start() {
    transport.start { [weak self] clientFD, request in
      guard let self else {
        close(clientFD)
        return
      }

      let response = handleRequest(request)
      _ = transport.send(response, to: clientFD)
      close(clientFD)
    }
  }

  /// Stops the server.
  func stop() {
    transport.stop()
  }
}
