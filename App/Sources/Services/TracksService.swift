import Foundation

struct TracksConfiguration: Equatable {
  var filters: [TracksFilter] = []
  var filteredTracks: [TracksFilter: [Track]] = [:]
  var filteredFavoriteTracks: [TracksFilter: [Track]] = [:]
  var filteredIndexTitles: [TracksFilter: [String: Int]] = [:]
}

final class TracksService {
  private var observation: NSObjectProtocol?

  private let favoritesService: FavoritesServiceProtocol
  private let persistenceService: PersistenceServiceProtocol

  init(favoritesService: FavoritesServiceProtocol, persistenceService: PersistenceServiceProtocol) {
    self.persistenceService = persistenceService
    self.favoritesService = favoritesService
  }

  func loadConfiguration(_ completion: @escaping (TracksConfiguration) -> Void) {
    persistenceService.performRead(GetAllTracks()) { [weak self] result in
      guard case let .success(tracks) = result, let self else { return }

      var configuration = TracksConfiguration()
      var filters: Set<TracksFilter> = [.all]

      for (offset, track) in tracks.enumerated() {
        let filter = TracksFilter.day(track.day)
        filters.insert(filter)
        configuration.filteredTracks[.all, default: []].append(track)
        configuration.filteredTracks[filter, default: []].append(track)

        if self.favoritesService.contains(track) {
          configuration.filteredFavoriteTracks[.all, default: []].append(track)
          configuration.filteredFavoriteTracks[filter, default: []].append(track)
        }

        if let initial = track.name.first, configuration.filteredIndexTitles[.all, default: [:]][String(initial)] == nil {
          configuration.filteredIndexTitles[.all, default: [:]][String(initial)] = offset
        }
      }

      for filter in filters.filter({ filter in filter != .all }) {
        let tracks = configuration.filteredTracks[filter] ?? []
        for (offset, track) in tracks.enumerated() {
          if let initial = track.name.first, configuration.filteredIndexTitles[filter, default: [:]][String(initial)] == nil {
            configuration.filteredIndexTitles[filter, default: [:]][String(initial)] = offset
          }
        }
      }

      configuration.filters = filters.sorted()

      DispatchQueue.main.async {
        completion(configuration)
      }
    }
  }
}

/// @mockable
protocol TracksServiceProtocol: AnyObject {
  func loadConfiguration(_ completion: @escaping (TracksConfiguration) -> Void)
}

extension TracksService: TracksServiceProtocol {}

protocol HasTracksService {
  var tracksService: TracksServiceProtocol { get }
}
