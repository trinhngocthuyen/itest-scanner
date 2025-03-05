import Foundation
import os

class LoggerConfig: @unchecked Sendable {
  var quiet = false
  var runningInsideXcode: Bool {
    ProcessInfo.processInfo.environment.keys.contains("__XCODE_BUILT_PRODUCTS_DIR_PATHS")
  }
}

struct Logger: Sendable {
  let systemLogger = os.Logger(subsystem: "com.thuyen.test_scanner", category: "General")
  let config = LoggerConfig()

  func debug(_ message: String) {
    systemLogger.debug("\(message, privacy: .public)")
    writeToFileHandle(.standardOutput, message: "\(message)\n")
  }

  func warning(_ message: String) {
    systemLogger.warning("[warning] \(message, privacy: .public)")
    writeToFileHandle(.standardError, message: "[warning] \(message)\n")
  }

  func error(_ message: String) {
    systemLogger.error("[error] \(message, privacy: .public)")
    writeToFileHandle(.standardError, message: "[error] \(message)\n")
  }

  private func writeToFileHandle(_ f: FileHandle, message: String) {
    if config.quiet || config.runningInsideXcode { return }
    try? f.write(contentsOf: Data(message.utf8))
  }
}

let logger = Logger()
