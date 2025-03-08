import IndexStoreDB

extension IndexStoreDB {
  func definition(ofUniqueName name: String) -> SymbolOccurrence? {
    canonicalOccurrences(ofName: name).first { $0.roles.contains(.definition) }
  }

  func definition(of symbol: Symbol) -> SymbolOccurrence? {
    occurrences(ofUSR: symbol.usr, roles: .definition).first
  }

  func xctestSymbolOccurrences() -> [SymbolOccurrence] {
    unitTests().filter { [.function, .instanceMethod].contains($0.symbol.kind) }
  }

  func swiftTestingSymbolNames() -> [String] {
    allSymbolNames().filter { $0.contains("__🟠$test_container__function__") }
  }

  func swiftTestingDefinitions() -> [SymbolOccurrence] {
    swiftTestingSymbolNames().compactMap { definition(ofUniqueName: $0) }
  }

  func swiftTestingSymbolOccurrences() -> [SymbolOccurrence] {
    swiftTestingDefinitions()
      .toSet { $0.location.path }
      .flatMap { path in
        symbols(inFilePath: path).compactMap { symbol in
          if occurrences(relatedToUSR: symbol.usr, roles: .containedBy).hasTestMacro() {
            return definition(of: symbol)
          }
          return nil
        }
      }
  }
}

extension Sequence<SymbolOccurrence> {
  func hasTestMacro() -> Bool {
    contains { $0.symbol.kind == .macro && $0.symbol.name.hasPrefix("Test(") }
  }
}
