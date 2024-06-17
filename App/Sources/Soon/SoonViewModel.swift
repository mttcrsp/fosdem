import Combine

final class SoonViewModel: Favoriting {
  typealias Dependencies = HasFavoritesService & HasSoonService

  @Published private(set) var events: [Event] = []
  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
  }

  var favoritesService: FavoritesServiceProtocol {
    dependencies.favoritesService
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
}
