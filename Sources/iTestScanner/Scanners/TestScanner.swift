import Foundation

final class TestScanner: BaseTestScanner {
  override func scan() throws -> [String] {
    let cls = getScannerCls()
    logger.debug("Use scanner: \(cls.desc)")
    return try cls.init(project: project).scan()
  }

  private func getScannerCls() -> BaseTestScanner.Type {
    if project.isSPMProject() {
      return SPMTestScanner.self
    }
    return IndexTestScanner.self
  }
}
