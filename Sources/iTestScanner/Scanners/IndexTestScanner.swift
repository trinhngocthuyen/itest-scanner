import Foundation
import IndexStoreDB

enum IndexTestScannerError: Error {
  case derivedDataNotFound
  case indexStoreNotFound
}

final class IndexTestScanner: BaseTestScanner {
  private lazy var index = try? loadIndex()

  override func scan() throws -> [String] {
    getXCTestIdentifiers() + getSwiftTestingIdetifiers()
  }

  override class var desc: String {
    "\(self) (parsing symbols from index store)"
  }

  private func loadIndex() throws -> IndexStoreDB? {
    let derivedDataPath = try project.derivedDataPath.wrap(
      throw: IndexTestScannerError.derivedDataNotFound,
      "Cannot find derived data for: \(project.root). Is this an iOS project?"
    )
    let indexStoreURL = try derivedDataPath.glob("Index.noindex/DataStore").first.wrap(
      throw: IndexTestScannerError.indexStoreNotFound,
      "Cannot find index in derived data: \(derivedDataPath).\nPossibly indexing is not yet triggered, or in-progress"
    )
    let indexDBURL = indexStoreURL.parent().appending(path: "test_scanner_db").deletingIfExist()

    logger.debug("Load index from: \(indexStoreURL)")
    let xcodeSelectPath = try sh.run("xcode-select -p").out
    let indexStoreDylibPath = "\(xcodeSelectPath)/Toolchains/XcodeDefault.xctoolchain/usr/lib/libIndexStore.dylib"
    let this = try IndexStoreDB(
      storePath: indexStoreURL.path(),
      databasePath: indexDBURL.path(),
      library: .init(dylibPath: indexStoreDylibPath)
    )
    this.pollForUnitChangesAndWait()
    return this
  }

  private func getXCTestIdentifiers() -> [String] {
    guard let index else { return [] }
    return index.xctestSymbolOccurrences()
      .map { definitionToIdentifier($0) }
      .map { $0.replacingOccurrences(of: "()", with: "") } // XCTest identifiers do not have parentheses at the end
  }

  private func getSwiftTestingIdetifiers() -> [String] {
    guard let index else { return [] }
    return index
      .swiftTestingSymbolOccurrences()
      .map { definitionToIdentifier($0) }
  }

  private func definitionToIdentifier(_ def: SymbolOccurrence) -> String {
    if def.location.moduleName.isEmpty {
      logger.warning("module name is empty for \(def.symbol.name)")
    }
    if let ctx = def.relations.first?.symbol {
      return "\(def.location.moduleName)/\(ctx.name)/\(def.symbol.name)"
    }
    return "\(def.location.moduleName)/\(def.symbol.name)"
  }
}
