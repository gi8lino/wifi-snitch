import Foundation

/// Runs child processes and returns stdout as UTF-8 text.
struct ProcessRunner {
    /// Runs the given executable with arguments and returns stdout on success.
    func run(executable: String, arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let stdout = Pipe()
        let stderr = Pipe()

        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
        } catch {
            return nil
        }

        process.waitUntilExit()

        let data = stdout.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return nil
        }

        return output
    }
}
