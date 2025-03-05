#if os(Linux)
import Glibc
#else
import Darwin
#endif
import Foundation

func globWithPattern(_ pattern: String) -> [String] {
  var gt = glob_t()
  #if os(Linux)
  let system_glob = Glibc.glob
  #else
  let system_glob = Darwin.glob
  #endif

  guard let cPattern = strdup(pattern) else { fatalError("Unexpected error") }

  defer {
    globfree(&gt)
    free(cPattern)
  }
  var results = [String]()
  let flags = GLOB_TILDE | GLOB_BRACE | GLOB_MARK
  if system_glob(cPattern, flags, nil, &gt) == 0 {
    #if os(Linux)
    let matchc = gt.gl_pathc
    #else
    let matchc = gt.gl_matchc
    #endif
    for i in 0 ..< Int(matchc) {
      if let cString = gt.gl_pathv[i], let path = String(validatingCString: cString) {
        results.append(path.withoutEndingSplash)
      }
    }
  }
  return results
}
