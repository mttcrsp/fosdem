#if DEBUG
final class DebugServices: Services {
  override init() throws {
    let testsService = TestsService()
    testsService.runPreInitializationTestCommands()
    try super.init()
    testsService.runPostInitializationTestCommands(with: self)
  }
}
#endif
