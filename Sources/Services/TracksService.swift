import Foundation
import Schedule

protocol TracksServiceDelegate: AnyObject {
  func tracksServiceDidUpdateTracks(_ tracksService: TracksService)

  func tracksService(_ tracksService: TracksService, performBatchUpdates updates: () -> Void)
  func tracksService(_ tracksService: TracksService, insertFavoriteWith identifier: String)
  func tracksService(_ tracksService: TracksService, deleteFavoriteWith identifier: String)
}

final class TracksService {
  weak var delegate: TracksServiceDelegate?

  var tracks: [Track] {
    filteredTracks[.all] ?? []
  }

  private var observation: NSObjectProtocol?
  private(set) var filters: [TracksFilter] = []
  private(set) var filteredTracks: [TracksFilter: [Track]] = [:]
  private(set) var filteredFavoriteTracks: [TracksFilter: [Track]] = [:]
  private(set) var filteredIndexTitles: [TracksFilter: [String: Int]] = [:]

  private let favoritesService: FavoritesService
  private let persistenceService: PersistenceService

  init(favoritesService: FavoritesService, persistenceService: PersistenceService) {
    self.persistenceService = persistenceService
    self.favoritesService = favoritesService
  }

  func loadTracks() {
    observation = favoritesService.addObserverForTracks { [weak self] identifier in
      self?.didToggleTrack(withIdentifier: identifier)
    }

    persistenceService.performRead(AllTracksOrderedByName()) { [weak self] result in
      if case let .success(tracks) = result {
        self?.didFinishLoading(with: tracks)
      }
    }
  }

  private func didFinishLoading(with tracks: [Track]) {
    var filters: Set<TracksFilter> = [.all]
    var filteredTracks: [TracksFilter: [Track]] = [:]
    var filteredFavoriteTracks: [TracksFilter: [Track]] = [:]
    var filteredIndexTitles: [TracksFilter: [String: Int]] = [:]

    for (offset, track) in tracks.enumerated() {
      let filter = TracksFilter.day(track.day)
      filters.insert(filter)
      filteredTracks[.all, default: []].append(track)
      filteredTracks[filter, default: []].append(track)

      if favoritesService.contains(track) {
        filteredFavoriteTracks[.all, default: []].append(track)
        filteredFavoriteTracks[filter, default: []].append(track)
      }

      if let initial = track.name.first, filteredIndexTitles[.all, default: [:]][String(initial)] == nil {
        filteredIndexTitles[.all, default: [:]][String(initial)] = offset
      }
    }

    for filter in filters.subtracting([.all]) {
      let tracks = filteredTracks[filter] ?? []
      for (offset, track) in tracks.enumerated() {
        if let initial = track.name.first, filteredIndexTitles[filter, default: [:]][String(initial)] == nil {
          filteredIndexTitles[filter, default: [:]][String(initial)] = offset
        }
      }
    }

    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }

      self.filters = filters.sorted()
      self.filteredTracks = filteredTracks
      self.filteredIndexTitles = filteredIndexTitles
      self.filteredFavoriteTracks = filteredFavoriteTracks
      self.delegate?.tracksServiceDidUpdateTracks(self)
    }
  }

  private func didToggleTrack(withIdentifier identifier: String) {
    let isFavorite = favoritesService.tracksIdentifiers.contains(identifier)

    let updates = {
      if !isFavorite {
        self.delegate?.tracksService(self, deleteFavoriteWith: identifier)
      }

      self.filteredFavoriteTracks = [:]
      for track in self.tracks where self.favoritesService.contains(track) {
        let filter = TracksFilter.day(track.day)
        self.filteredFavoriteTracks[.all, default: []].append(track)
        self.filteredFavoriteTracks[filter, default: []].append(track)
      }

      if isFavorite {
        self.delegate?.tracksService(self, insertFavoriteWith: identifier)
      }
    }

    if let delegate = delegate {
      delegate.tracksService(self, performBatchUpdates: updates)
    } else {
      updates()
    }
  }
}
