public func scanTests(
  in projectRoot: String,
  derivedDataPath: String?,
  quiet: Bool = false,
  strategy: String? = nil
) throws -> [String] {
  logger.config.quiet = quiet
  logger.debug("Scanning tests for project: \(projectRoot)...\n")
  return try TestScanner(
    projectRoot: projectRoot,
    derivedDataPath: derivedDataPath
  ).withStrategy(strategy).scan()
}
