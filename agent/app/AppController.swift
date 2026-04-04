import AppKit
import CoreLocation
import EasyBarShared
import Foundation
import WiFiSnitchShared

final class AppController: NSObject, CLLocationManagerDelegate {
  private let locationManager = CLLocationManager()
  private let authState = NetworkAgentAuthorizationState()
  private let retryBackoff = AuthorizationRetryBackoff()

  private let wifiProvider = WiFiProvider()
  private let networkProvider = NetworkStateProvider()
  private let encoder = StatusFieldEncoder()

  private lazy var requestHandler = StatusRequestHandler(
    wifiProvider: wifiProvider,
    networkProvider: networkProvider,
    authState: authState,
    encoder: encoder
  )

  private var server: StatusAgentServer?
  private var presentedAuthorizationPrompt = false

  /// Starts location tracking and starts the socket server.
  @MainActor
  func start() {
    locationManager.delegate = self
    authState.setStatus(locationManager.authorizationStatus)
    requestAccessIfNeeded()

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

  /// Stops the socket server.
  @MainActor
  func stop() {
    retryBackoff.reset()
    restoreAccessoryModeIfNeeded()
    locationManager.delegate = nil
    server?.stop()
    server = nil
  }

  /// Updates cached location authorization state.
  nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let status = manager.authorizationStatus

    DispatchQueue.main.async { [weak self] in
      guard let self else { return }

      self.authState.setStatus(status)
      self.handleAuthorizationStateChange(status)
    }
  }

  /// Requests location access when the current state allows it.
  @MainActor
  private func requestAccessIfNeeded() {
    let status = locationManager.authorizationStatus
    authState.setStatus(status)

    switch status {
    case .authorized, .authorizedAlways, .authorizedWhenInUse:
      retryBackoff.reset()
      restoreAccessoryModeIfNeeded()

    case .notDetermined:
      prepareAuthorizationPromptIfNeeded()
      locationManager.requestWhenInUseAuthorization()
      scheduleRetry()

    case .denied, .restricted:
      retryBackoff.reset()
      restoreAccessoryModeIfNeeded()

    @unknown default:
      retryBackoff.reset()
      restoreAccessoryModeIfNeeded()
    }
  }

  /// Updates retry handling after one authorization state change.
  @MainActor
  private func handleAuthorizationStateChange(_ status: CLAuthorizationStatus) {
    switch status {
    case .authorized, .authorizedAlways, .authorizedWhenInUse, .denied, .restricted:
      retryBackoff.reset()
      restoreAccessoryModeIfNeeded()

    case .notDetermined:
      scheduleRetry()

    @unknown default:
      retryBackoff.reset()
    }
  }

  /// Schedules one follow-up authorization check.
  @MainActor
  private func scheduleRetry() {
    retryBackoff.schedule { [weak self] in
      Task { @MainActor in
        self?.requestAccessIfNeeded()
      }
    }
  }

  /// Temporarily promotes the app so macOS can surface the permission prompt.
  @MainActor
  private func prepareAuthorizationPromptIfNeeded() {
    guard !presentedAuthorizationPrompt else { return }

    presentedAuthorizationPrompt = true
    _ = NSApp.setActivationPolicy(.regular)
    NSApp.activate(ignoringOtherApps: true)
  }

  /// Restores accessory mode after the permission state resolves.
  @MainActor
  private func restoreAccessoryModeIfNeeded() {
    guard presentedAuthorizationPrompt else { return }

    presentedAuthorizationPrompt = false
    _ = NSApp.setActivationPolicy(.accessory)
  }
}
