#if DEBUG
final class DebugClients: Clients {
  override init() throws {
    let testsClient = TestsClient()
    testsClient.runPreInitializationTestCommands()
    try super.init()
    testsClient.runPostInitializationTestCommands(with: self)
  }
}
#endif
