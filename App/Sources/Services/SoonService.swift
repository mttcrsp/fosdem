final class SoonService {
  private let persistenceService: PersistenceServiceProtocol
  private let timeService: TimeServiceProtocol

  init(timeService: TimeServiceProtocol, persistenceService: PersistenceServiceProtocol) {
    self.persistenceService = persistenceService
    self.timeService = timeService
  }

  func loadEvents(completion: @escaping (Result<[Event], Error>) -> Void) {
    let operation = GetEventsStartingIn30Minutes(now: timeService.now)
    persistenceService.performRead(operation, completion: completion)
  }
}

// @mockable
protocol SoonServiceProtocol {
  func loadEvents(completion: @escaping (Result<[Event], Error>) -> Void)
}

extension SoonService: SoonServiceProtocol {}

protocol HasSoonService {
  var soonService: SoonServiceProtocol { get }
}
