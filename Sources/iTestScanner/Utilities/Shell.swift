import Foundation

enum ShellError: LocalizedError, Sendable {
  case execError(code: Int, stderr: String?)
}

struct Shell {
  func run(
    _ command: String,
    pwd: String? = nil,
    logCmd: Bool = false,
    extraLog: String? = nil
  ) throws -> (out: String, err: String?) {
    let task = Process()
    let stdout = Pipe()
    let stderr = Pipe()
    let pwd = pwd ?? FileManager.default.currentDirectoryPath

    task.executableURL = URL(fileURLWithPath: "/bin/sh")
    task.arguments = ["-c", command]
    task.currentDirectoryURL = URL(filePath: pwd)
    task.standardOutput = stdout
    task.standardError = stderr

    func readFrom(_ pipe: Pipe) throws -> String? {
      try pipe.fileHandleForReading.readToEnd().flatMap { data in
        String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
      }
    }

    if logCmd {
      logger.debug("Run command: `\(command)` (in: \(pwd))")
    }
    if let extraLog {
      logger.debug(extraLog)
    }
    try task.run()
    let out = try? readFrom(stdout)
    let err = try? readFrom(stderr)
    task.waitUntilExit()
    if task.terminationStatus > 0 {
      throw ShellError.execError(code: Int(task.terminationStatus), stderr: err)
    }
    return (out: out ?? "", err: err)
  }
}

let sh = Shell()
