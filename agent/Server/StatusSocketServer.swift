import Darwin
import Foundation
import WiFiSnitchShared

/// Serves status requests over a Unix domain socket.
final class StatusSocketServer {
  private let socketPath: String
  private let handleRequest: (String) -> String

  private let stateLock = NSLock()
  private let acceptQueue = DispatchQueue(label: "wifisnitch.socket.accept", qos: .utility)
  private let clientQueue = DispatchQueue(
    label: "wifisnitch.socket.client", qos: .utility, attributes: .concurrent)

  private var serverFD: Int32 = -1
  private var running = false

  /// Creates a server for the given socket path.
  init(socketPath: String, handleRequest: @escaping (String) -> String) {
    self.socketPath = socketPath
    self.handleRequest = handleRequest
  }

  deinit {
    stop()
  }

  /// Starts listening on the Unix domain socket.
  func start() {
    stateLock.lock()
    defer { stateLock.unlock() }

    guard !running else { return }

    let socketURL = URL(fileURLWithPath: socketPath)
    let socketDir = socketURL.deletingLastPathComponent()

    try? FileManager.default.createDirectory(at: socketDir, withIntermediateDirectories: true)
    unlink(socketPath)

    let fd = socket(AF_UNIX, SOCK_STREAM, 0)
    guard fd >= 0 else { return }

    var addr = makeSockAddrUn(path: socketPath)
    let addrLen = socklen_t(MemoryLayout<sockaddr_un>.size)

    let bindResult = withUnsafePointer(to: &addr) {
      $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        bind(fd, $0, addrLen)
      }
    }

    guard bindResult == 0 else {
      close(fd)
      return
    }

    chmod(socketPath, mode_t(0o600))

    guard listen(fd, 8) == 0 else {
      close(fd)
      unlink(socketPath)
      return
    }

    serverFD = fd
    running = true

    acceptQueue.async { [weak self] in
      self?.acceptLoop()
    }
  }

  /// Stops the server and removes the socket file.
  func stop() {
    stateLock.lock()

    let fd = serverFD
    let wasRunning = running

    running = false
    serverFD = -1

    stateLock.unlock()

    guard wasRunning else { return }

    if fd >= 0 {
      shutdown(fd, SHUT_RDWR)
      close(fd)
    }

    unlink(socketPath)
  }

  /// Accepts client connections until the server stops.
  private func acceptLoop() {
    while isRunning() {
      let fd = currentServerFD()
      if fd < 0 { break }

      let clientFD = accept(fd, nil, nil)
      if clientFD < 0 {
        if !isRunning() {
          break
        }
        continue
      }

      clientQueue.async { [weak self] in
        self?.handleClient(clientFD)
      }
    }
  }

  /// Handles one client request and writes the response.
  private func handleClient(_ clientFD: Int32) {
    defer { close(clientFD) }

    var buffer = [UInt8](repeating: 0, count: 4096)
    let n = read(clientFD, &buffer, buffer.count)
    if n <= 0 { return }

    let request = String(decoding: buffer.prefix(n), as: UTF8.self)
      .trimmingCharacters(in: .whitespacesAndNewlines)

    let response = handleRequest(request)
    sendAll(clientFD, Data((response + "\n").utf8))
  }

  /// Returns whether the server is running.
  private func isRunning() -> Bool {
    stateLock.lock()
    defer { stateLock.unlock() }
    return running
  }

  /// Returns the current server file descriptor.
  private func currentServerFD() -> Int32 {
    stateLock.lock()
    defer { stateLock.unlock() }
    return serverFD
  }

  /// Writes all bytes in the response to the client.
  private func sendAll(_ fd: Int32, _ data: Data) {
    data.withUnsafeBytes { rawBuffer in
      guard let base = rawBuffer.baseAddress else { return }

      var sent = 0
      while sent < data.count {
        let n = write(fd, base.advanced(by: sent), data.count - sent)
        if n <= 0 { break }
        sent += n
      }
    }
  }
}
