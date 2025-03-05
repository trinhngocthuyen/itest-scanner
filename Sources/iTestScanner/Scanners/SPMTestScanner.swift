final class SPMTestScanner: BaseTestScanner {
  override func scan() throws -> [String] {
    let output = try sh.run(
      "xcrun swift test list",
      pwd: project.root.path(),
      logCmd: true,
      extraLog: "This may take a while..."
    ).out
    return output.split(separator: "\n").map { line in
      line.replacingOccurrences(of: ".", with: "/")
    }
  }

  override class var desc: String {
    "\(self) (particularly to SPM projects)"
  }
}
