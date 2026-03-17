import Darwin
import Foundation

guard let options = parseArgs() else {
    exit(0)
}

do {
    let reply = try SocketClient(socketPath: options.socketPath).send(request: options.request)
    print(reply, terminator: "")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
