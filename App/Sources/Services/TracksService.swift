import Foundation

struct TracksConfiguration: Equatable {
  var filters: [TracksFilter] = []
  var filteredTracks: [TracksFilter: [Track]] = [:]
  var filteredFavoriteTracks: [TracksFilter: [Track]] = [:]
  var filteredIndexTitles: [TracksFilter: [String: Int]] = [:]
}

struct TracksService {
  var loadConfiguration: (@escaping (TracksConfiguration) -> Void) -> Void
}

extension TracksService {
  init(favoritesService: FavoritesServiceProtocol, persistenceService: PersistenceServiceProtocol) {
    loadConfiguration = { completion in
      persistenceService.allTracks { result in
        guard case let .success(tracks) = result else { return }

        var configuration = TracksConfiguration()
        var filters: Set<TracksFilter> = [.all]

        for (offset, track) in tracks.enumerated() {
          let filter = TracksFilter.day(track.day)
          filters.insert(filter)
          configuration.filteredTracks[.all, default: []].append(track)
          configuration.filteredTracks[filter, default: []].append(track)

          if favoritesService.contains(track) {
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
}

/// @mockable
protocol TracksServiceProtocol {
  var loadConfiguration: (@escaping (TracksConfiguration) -> Void) -> Void { get }
}

extension TracksService: TracksServiceProtocol {}

protocol HasTracksService {
  var tracksService: TracksServiceProtocol { get }
}
