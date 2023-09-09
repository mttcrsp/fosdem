struct SoonService {
  var loadEvents: (@escaping (Result<[Event], Error>) -> Void) -> Void
}

extension SoonService {
  init(timeService: TimeServiceProtocol, persistenceService: PersistenceServiceProtocol) {
    loadEvents = { completion in
      let operation = GetEventsStartingIn30Minutes(now: timeService.now())
      persistenceService.performRead(operation, completion: completion)
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
