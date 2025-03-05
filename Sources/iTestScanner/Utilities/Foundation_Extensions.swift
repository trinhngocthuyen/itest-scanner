import Foundation

extension String {
  var quoted: String {
    "\"\(self)\""
  }

  var withoutEndingSplash: String {
    hasSuffix("/") ? String(dropLast()) : self
  }
}

extension URL {
  func parent(upLevel: Int = 1) -> URL {
    var result = self
    for _ in 0 ..< upLevel {
      result = result.deletingLastPathComponent()
    }
    return URL(filePath: result.path().withoutEndingSplash)
  }

  func glob(_ pattern: String) -> [URL] {
    globWithPattern("\(path().withoutEndingSplash)/\(pattern)").compactMap(URL.init)
  }
}

extension Optional {
  func wrap(throw error: Error, _ msg: String) throws -> Wrapped {
    if let wrapped = self {
      return wrapped
    }
    logger.error(msg)
    throw error
  }
}
