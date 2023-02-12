import Foundation

protocol TracksServiceDelegate: AnyObject {
  func tracksServiceDidUpdateTracks(_ tracksService: TracksService)
  func tracksService(_ tracksService: TracksService, performBatchUpdates updates: () -> Void)
  func tracksService(_ tracksService: TracksService, didInsertFavoriteAt index: Int)
  func tracksService(_ tracksService: TracksService, didDeleteFavoriteAt index: Int)
  func tracksServiceDidInsertFirstFavorite(_ tracksService: TracksService)
  func tracksServiceDidDeleteLastFavorite(_ tracksService: TracksService)
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

  private let favoritesService: FavoritesServiceProtocol
  private let persistenceService: PersistenceService

  init(favoritesService: FavoritesServiceProtocol, persistenceService: PersistenceService) {
    self.persistenceService = persistenceService
    self.favoritesService = favoritesService
  }

  func loadTracks() {
    observation = favoritesService.addObserverForTracks { [weak self] in
      self?.didUpdateFavoriteTracks()
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

  private func didUpdateFavoriteTracks() {
    var oldTracks = filteredFavoriteTracks[.all]?.map(\.name) ?? []
    let newTracks = favoritesService.tracksIdentifiers.sorted { lhs, rhs in
      lhs.lowercased() < rhs.lowercased()
    }

    let deletesIdentifiers = Set(oldTracks).subtracting(Set(newTracks))
    let insertsIdentifiers = Set(newTracks).subtracting(Set(oldTracks))

    let updates = {
      self.filteredFavoriteTracks = [:]
      for track in self.tracks where self.favoritesService.contains(track) {
        let filter = TracksFilter.day(track.day)
        self.filteredFavoriteTracks[.all, default: []].append(track)
        self.filteredFavoriteTracks[filter, default: []].append(track)
      }

      switch (oldTracks.isEmpty, newTracks.isEmpty) {
      case (true, false):
        self.delegate?.tracksServiceDidInsertFirstFavorite(self)
      case (false, true):
        self.delegate?.tracksServiceDidDeleteLastFavorite(self)
      default:
        break
      }

      for (index, track) in oldTracks.enumerated().reversed() where deletesIdentifiers.contains(track) {
        self.delegate?.tracksService(self, didDeleteFavoriteAt: index)
        oldTracks.remove(at: index)
      }

      for (index, track) in newTracks.enumerated() where insertsIdentifiers.contains(track) {
        self.delegate?.tracksService(self, didInsertFavoriteAt: index)
        oldTracks.insert(track, at: index)
      }
    }

    if let delegate = delegate {
      delegate.tracksService(self, performBatchUpdates: updates)
    } else {
      updates()
    }
  }
}

/// @mockable
protocol TracksServiceProtocol: AnyObject {
  var delegate: TracksServiceDelegate? { get set }

  var tracks: [Track] { get }

  var filters: [TracksFilter] { get }
  var filteredTracks: [TracksFilter: [Track]] { get }
  var filteredFavoriteTracks: [TracksFilter: [Track]] { get }
  var filteredIndexTitles: [TracksFilter: [String: Int]] { get }

  func loadTracks()
}

extension TracksService: TracksServiceProtocol {}

protocol HasTracksService {
  var tracksService: TracksServiceProtocol { get }
}
