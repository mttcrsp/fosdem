import Combine
import Foundation

final class AgendaViewModel: Favoriting {
  typealias Dependencies = HasFavoritesService & HasPersistenceService & HasSoonService & HasTimeService

  let didFail = PassthroughSubject<Error, Never>()
  @Published private(set) var events: [Event] = []
  @Published private(set) var liveEventsIDs: Set<Int> = []
  private var observations: [NSObjectProtocol] = []
  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
  }

  var favoritesService: FavoritesServiceProtocol {
    dependencies.favoritesService
  }

  func didLoad() {
    loadFavoriteEvents()
    observations = [
      dependencies.favoritesService.addObserverForEvents { [weak self] in
        self?.loadFavoriteEvents()
      },
      dependencies.timeService.addObserver { [weak self] in
        guard let self else { return }

        var liveEventsIDs: Set<Int> = []
        for event in events where event.isLive(at: dependencies.timeService.now) {
          liveEventsIDs.insert(event.id)
        }

        self.liveEventsIDs = liveEventsIDs
      },
    ]
  }
}

private extension AgendaViewModel {
  func loadFavoriteEvents() {
    let identifiers = dependencies.favoritesService.eventsIdentifiers
    let operation = GetEventsByIdentifiers(identifiers: identifiers)
    dependencies.persistenceService.performRead(operation) { [weak self] result in
      switch result {
      case let .success(events):
        self?.events = events
      case let .failure(error):
        self?.didFail.send(error)
      }
    }
  }
}
