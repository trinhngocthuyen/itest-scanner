import Foundation

final class TestScanner: BaseTestScanner {
  private var strategy: String? = nil
  private var strategyToCls: [String: BaseTestScanner.Type] = [
    "spm": SPMTestScanner.self,
    "index": IndexTestScanner.self,
  ]

  override func scan() throws -> [String] {
    let cls = getScannerCls()
    logger.debug("Use scanner: \(cls.desc)")
    return try cls.init(project: project).scan()
  }

  func withStrategy(_ strategy: String?) -> Self {
    self.strategy = strategy
    return self
  }

  private func getScannerCls() -> BaseTestScanner.Type {
    if let strategy, let cls = strategyToCls[strategy] { return cls }
    if project.isSPMProject() {
      return SPMTestScanner.self
    }
    return IndexTestScanner.self
  }
}
