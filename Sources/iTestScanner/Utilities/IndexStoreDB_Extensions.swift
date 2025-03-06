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

  func swiftTestingMacroRelation(attachedTo symbol: Symbol) -> SymbolRelation? {
    let macroOccurrence = occurrences(relatedToUSR: symbol.usr, roles: .containedBy)
      .first { occ in occ.symbol.name.hasPrefix("Test(") && occ.symbol.kind == .macro }
    return macroOccurrence?.relations.first { occ in occ.roles.contains(.containedBy) }
  }

  func swiftTestingSymbolOccurrences() -> [SymbolOccurrence] {
    swiftTestingDefinitions()
      .toSet { $0.location.path }
      .flatMap { path in
        symbols(inFilePath: path).compactMap { symbol in
          let attachedSymbol = swiftTestingMacroRelation(attachedTo: symbol)?.symbol
          return attachedSymbol.flatMap { definition(of: $0) }
        }
      }
  }
}
