struct SoonService {
  var loadEvents: (@escaping (Result<[Event], Error>) -> Void) -> Void
}

extension SoonService {
  init(timeService: TimeServiceProtocol, persistenceService: PersistenceServiceProtocol) {
    loadEvents = { completion in
      persistenceService.eventsStartingIn30Minutes(timeService.now(), completion)
    }
  }
}

// @mockable
protocol SoonServiceProtocol {
  var loadEvents: (@escaping (Result<[Event], Error>) -> Void) -> Void { get }
}

extension SoonService: SoonServiceProtocol {}

protocol HasSoonService {
  var soonService: SoonServiceProtocol { get }
}
