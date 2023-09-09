struct SoonClient {
  var loadEvents: (@escaping (Result<[Event], Error>) -> Void) -> Void
}

extension SoonClient {
  init(timeClient: TimeClientProtocol, persistenceClient: PersistenceClientProtocol) {
    loadEvents = { completion in
      persistenceClient.eventsStartingIn30Minutes(timeClient.now(), completion)
    }
  }
}

// @mockable
protocol SoonClientProtocol {
  var loadEvents: (@escaping (Result<[Event], Error>) -> Void) -> Void { get }
}

extension SoonClient: SoonClientProtocol {}
