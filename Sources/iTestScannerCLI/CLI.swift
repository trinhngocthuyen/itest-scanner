import ArgumentParser
import Foundation
import iTestScanner

@main
struct CLI: ParsableCommand {
  @Option(help: "Project root")
  var projectRoot: String = FileManager.default.currentDirectoryPath

  @Option(help: "Derived data path")
  var derivedDataPath: String?

  @Option(name: .shortAndLong, help: "Output path (JSON)")
  var outputPath: String?

  @Flag(name: .shortAndLong, help: "Quiet")
  var quiet: Bool = false

  mutating func run() throws {
    let tests = try scanTests(
      in: projectRoot,
      derivedDataPath: derivedDataPath,
      quiet: quiet
    )
    try dumpResults(tests)
  }

  private func dumpResults(_ object: Any) throws {
    let jsonData = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .withoutEscapingSlashes])
    if let jsonString = String(data: jsonData, encoding: .utf8) {
      print(quiet ? jsonString : "\nExtracted tests:\n\n\(jsonString)")
    }
    if let outputPath {
      FileManager.default.createFile(atPath: outputPath, contents: jsonData)
    }
  }
}
