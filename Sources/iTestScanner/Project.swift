import Foundation

struct Project {
  let root: URL
  var workspaceURL: URL?
  var projectURL: URL?
  var derivedDataPath: URL?
  var sharedSchemes: [URL] = []
  var userSchemes: [URL] = []
  var schemes: [URL] { sharedSchemes + userSchemes }
  var scheme: String? {
    schemes.first?.deletingPathExtension().lastPathComponent
  }

  init(root: String, derivedDataPath: String? = nil) {
    self.root = URL(filePath: NSString(string: root).expandingTildeInPath).absoluteURL
    self.derivedDataPath = derivedDataPath.map { URL(filePath: $0).absoluteURL }
    resolve()
  }

  private mutating func resolve() {
    workspaceURL = root.glob("*.xcworkspace").first
    projectURL = root.glob("*.xcodeproj").first
    if let projectURL {
      sharedSchemes += projectURL.glob("xcshareddata/xcschemes/*.xcscheme")
      userSchemes += projectURL.glob("xcuserdata/*/xcschemes/*.xcscheme")
    }
    if derivedDataPath == nil, !isSPMProject() {
      logger.debug("Resolving derived data path from build settings...")
      derivedDataPath = try? resolveBuildSettings().derivedDataPath
      logger.debug("-> Derived data path: \(derivedDataPath?.path() ?? "nil")")
    }
  }

  private func resolveBuildSettings() throws -> BuildSettings {
    var cmps = ["xcodebuild", "-showBuildSettings"]
    if let scheme {
      cmps += ["-scheme", scheme.quoted]
    }
    if let workspaceURL {
      cmps += ["-workspace", workspaceURL.path().quoted]
    } else if let projectURL {
      cmps += ["-project", projectURL.path().quoted]
    }
    let output = try sh.run(cmps.joined(separator: " "), pwd: root.path(), logCmd: true).out
    var results = [String: String]()
    for line in output.split(separator: "\n") {
      if let m = try? /\s+(\S+) = (.*)/.firstMatch(in: line) {
        results[String(m.output.1)] = String(m.output.2)
      }
    }
    return BuildSettings(underlying: results)
  }
}

extension Project {
  func withDerivedData(_ value: URL) -> Self {
    var copy = self
    copy.derivedDataPath = value
    return copy
  }

  func isSPMProject() -> Bool {
    !root.glob("Package*.swift").isEmpty
  }
}

struct BuildSettings {
  let underlying: [String: String]
  init(underlying: [String: String] = [:]) {
    self.underlying = underlying
  }

  subscript(key: String) -> String? {
    underlying[key]
  }

  var buildDir: URL? {
    self["BUILD_DIR"].map { URL(filePath: $0) }
  }

  var derivedDataPath: URL? {
    buildDir?.parent(upLevel: 2)
  }
}
