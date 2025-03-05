import Foundation

class BaseTestScanner {
  let project: Project

  init(projectRoot: String, derivedDataPath: String? = nil) {
    project = Project(root: projectRoot, derivedDataPath: derivedDataPath)
  }

  required init(project: Project) {
    self.project = project
  }

  func scan() throws -> [String] {
    fatalError("Not implemented")
  }

  class var desc: String { fatalError("Not implemented") }
}
