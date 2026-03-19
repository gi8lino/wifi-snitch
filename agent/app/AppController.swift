import CoreLocation
import Foundation
import WiFiSnitchShared

final class AppController: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let authState = AuthState()

    private let wifiProvider = WiFiProvider()
    private let networkProvider = NetworkStateProvider()
    private let encoder = StatusFieldEncoder()

    private lazy var requestHandler = StatusRequestHandler(
        wifiProvider: wifiProvider,
        networkProvider: networkProvider,
        authState: authState,
        encoder: encoder
    )

    private var server: StatusSocketServer?

    /// Starts location tracking and starts the socket server.
    @MainActor
    func start() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()

        authState.setStatus(locationManager.authorizationStatus)

        server = StatusSocketServer(
            socketPath: defaultSocketPath(),
            handleRequest: { [weak self] request in
                guard let self else { return "ERR server_unavailable" }
                return self.requestHandler.handle(request: request)
            }
        )

        server?.start()
    }

    /// Stops the socket server.
    @MainActor
    func stop() {
        server?.stop()
        server = nil
    }

    /// Updates cached location authorization state.
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        authState.setStatus(status)
    }
}
