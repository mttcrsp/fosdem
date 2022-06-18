#if DEBUG
final class DebugServices: Services {
  override init(persistenceService: PersistenceService) {
    let testsService = TestsService()
    testsService.runPreInitializationTestCommands()
    super.init(persistenceService: persistenceService)
    testsService.runPostInitializationTestCommands(with: self)
  }
}
#endif
