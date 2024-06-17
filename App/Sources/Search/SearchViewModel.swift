import Combine
import Foundation

final class SearchViewModel: Favoriting {
  typealias Dependencies = HasFavoritesService & HasPersistenceService & HasTracksService & HasYearsService

  @Published private(set) var selectedFilter: TracksFilter = .all
  @Published private(set) var tracksConfiguration: TracksConfiguration?
  @Published private(set) var observer: NSObjectProtocol?
  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
  }

  var favoritesService: FavoritesServiceProtocol {
    dependencies.favoritesService
  }

  var year: Year {
    type(of: dependencies.yearsService).current
  }

  func didLoad() {
    loadTracks()
    observer = dependencies.favoritesService.addObserverForTracks { [weak self] in
      self?.loadTracks()
    }
  }

  func didSelectFilter(_ filter: TracksFilter) {
    selectedFilter = filter
  }
}

private extension SearchViewModel {
  private func loadTracks() {
    dependencies.tracksService.loadConfiguration { [weak self] tracksConfiguration in
      self?.tracksConfiguration = tracksConfiguration
    }
  }
}
