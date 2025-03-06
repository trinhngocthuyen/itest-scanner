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
    return index.unitTests()
      .filter { [.function, .instanceMethod].contains($0.symbol.kind) }
      .map { definitionToIdentifier($0) }
      .map { $0.replacingOccurrences(of: "()", with: "") } // XCTest identifiers do not have parentheses at the end
  }

  private func getSwiftTestingIdetifiers() -> [String] {
    guard let index else { return [] }
    let names = index.allSymbolNames().filter { $0.contains("__🟠$test_container__function__") }
    return names.compactMap { name in
      findMacroSymbol(name: name, index: index)
        .flatMap { index.definition(of: $0) }
        .map { definitionToIdentifier($0) }
    }
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

  static let TEST_MACRO_TOKEN = "__🟠$test_container__function__"

  private func findMacroSymbol(name: String, index: IndexStoreDB) -> Symbol? {
    assert(name.contains(Self.TEST_MACRO_TOKEN))

    guard let definition = index.definition(of: name) else {
      logger.error("Cannot find definition of: \(name)")
      return nil
    }

    // We only care about functions & instance methods.
    // Also, symbols ending with `fMu_()` are excluded as they are of expanded forms.
    let symbols = index
      .symbols(inFilePath: definition.location.path)
      .filter { symbol in [.function, .instanceMethod].contains(symbol.kind) }
      .filter { symbol in !symbol.name.hasSuffix("fMu_()") }
    let toMatch = String(name.split(separator: Self.TEST_MACRO_TOKEN).last ?? "")
      .replacing(#/func(.*)fMu_/#) { m in m.output.1 }
      .replacing(#/(.*)async/#) { m in m.output.1 }
      .replacing(#/(.*)throws/#) { m in m.output.1 }
    return symbols.first { symbol in
      (try? toMatch.contains(patternize(fn: symbol.name))) ?? false
    }
  }

  private var cachedPatterns: [String: Regex<AnyRegexOutput>] = [:]
  private func patternize(fn: String) throws -> Regex<AnyRegexOutput> {
    if let cache = cachedPatterns[fn] { return cache }
    let pattern = fn
      .replacing("_:", with: String("\\S+_\\S+"))
      .replacing(":", with: String("_\\S+"))
      .replacing(#/[\(\)]/#, with: "_")
    do {
      let regex = try Regex("\(pattern)$")
      cachedPatterns[fn] = regex
      return regex
    } catch {
      logger.error("Fail to create regex with \(pattern): \(error)")
      throw error
    }
  }
}
