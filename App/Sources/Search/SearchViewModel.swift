import Combine
import Foundation

final class SearchViewModel {
  typealias Dependencies = HasFavoritesService & HasPersistenceService & HasTracksService & HasYearsService

  @Published private(set) var selectedFilter: TracksFilter = .all
  @Published private(set) var tracksConfiguration: TracksConfiguration?
  @Published private(set) var observer: NSObjectProtocol?
  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
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

  func canFavorite(_ event: Event) -> Bool {
    !dependencies.favoritesService.contains(event)
  }

  func didFavorite(_ event: Event) {
    dependencies.favoritesService.addEvent(withIdentifier: event.id)
  }

  func didUnfavorite(_ event: Event) {
    dependencies.favoritesService.removeEvent(withIdentifier: event.id)
  }

  func canFavorite(_ track: Track) -> Bool {
    !dependencies.favoritesService.contains(track)
  }

  func didFavorite(_ track: Track) {
    dependencies.favoritesService.addTrack(withIdentifier: track.name)
  }

  func didUnfavorite(_ track: Track) {
    dependencies.favoritesService.removeTrack(withIdentifier: track.name)
  }
}

private extension SearchViewModel {
  private func loadTracks() {
    dependencies.tracksService.loadConfiguration { [weak self] tracksConfiguration in
      self?.tracksConfiguration = tracksConfiguration
    }
  }
}
