import Darwin
import Foundation

enum SocketClientError: Error, CustomStringConvertible {
  case socketFailed
  case connectFailed(String)
  case writeFailed(String)
  case noReply

  var description: String {
    switch self {
    case .socketFailed:
      return "socket failed"
    case .connectFailed(let message):
      return "connect failed: \(message)"
    case .writeFailed(let message):
      return "write failed: \(message)"
    case .noReply:
      return "no reply"
    }
  }
}

/// Sends protocol requests over a Unix domain socket.
struct SocketClient {
  let socketPath: String

  /// Sends a request and returns the full reply.
  func send(request: String) throws -> String {
    let fd = socket(AF_UNIX, SOCK_STREAM, 0)
    guard fd >= 0 else {
      throw SocketClientError.socketFailed
    }

    defer { close(fd) }

    var addr = makeSockAddrUn(path: socketPath)
    let addrLen = socklen_t(MemoryLayout<sockaddr_un>.size)

    let connectResult = withUnsafePointer(to: &addr) {
      $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        connect(fd, $0, addrLen)
      }
    }

    guard connectResult == 0 else {
      throw SocketClientError.connectFailed(String(cString: strerror(errno)))
    }

    try sendAll(fd, Data((request + "\n").utf8))
    let reply = readAll(fd)

    guard !reply.isEmpty else {
      throw SocketClientError.noReply
    }

    return reply
  }

  /// Writes all bytes to the socket.
  private func sendAll(_ fd: Int32, _ data: Data) throws {
    try data.withUnsafeBytes { rawBuffer in
      guard let base = rawBuffer.baseAddress else { return }

      var sent = 0
      while sent < data.count {
        let n = write(fd, base.advanced(by: sent), data.count - sent)
        if n < 0 {
          throw SocketClientError.writeFailed(String(cString: strerror(errno)))
        }
        if n == 0 {
          break
        }
        sent += n
      }
    }
  }

  /// Reads until EOF.
  private func readAll(_ fd: Int32) -> String {
    var data = Data()
    var buffer = [UInt8](repeating: 0, count: 4096)

    while true {
      let n = read(fd, &buffer, buffer.count)
      if n <= 0 { break }

      data.append(buffer, count: n)
    }

    return String(decoding: data, as: UTF8.self)
  }
}
