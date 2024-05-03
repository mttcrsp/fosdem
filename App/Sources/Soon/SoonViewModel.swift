import Combine

final class SoonViewModel {
  typealias Dependencies = HasFavoritesService & HasSoonService

  @Published private(set) var events: [Event] = []
  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
  }

  func didLoad() {
    dependencies.soonService.loadEvents { [weak self] result in
      switch result {
      case let .success(events):
        self?.events = events
      case .failure:
        break
      }
    }
  }

  func canFavorite(_ event: Event) -> Bool {
    !dependencies.favoritesService.contains(event)
  }

  func didFavorite(_ event: Event) {
    dependencies.favoritesService.addEvent(withIdentifier: event.id)
  }

  func didUnfavorite(_ event: Event) {
    dependencies.favoritesService.removeEvent(withIdentifier: event.id)
  }
}
