import IndexStoreDB

extension IndexStoreDB {
  func definition(of name: String) -> SymbolOccurrence? {
    canonicalOccurrences(ofName: name).first { $0.roles.contains(.definition) }
  }

  func definition(of symbol: Symbol) -> SymbolOccurrence? {
    occurrences(ofUSR: symbol.usr, roles: .definition).first
  }
}
