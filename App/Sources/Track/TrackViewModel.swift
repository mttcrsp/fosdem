import Combine
import Foundation

final class TrackViewModel: Favoriting {
  typealias Dependencies = HasFavoritesService & HasPersistenceService

  let track: Track
  let didFail = PassthroughSubject<Error, Never>()
  @Published private(set) var captions: [Event: String] = [:]
  @Published private(set) var events: [Event] = []
  @Published private(set) var isTrackFavorite = false
  private var observer: NSObjectProtocol?
  private let dependencies: Dependencies

  init(track: Track, dependencies: Dependencies) {
    self.track = track
    self.dependencies = dependencies
  }

  var favoritesService: FavoritesServiceProtocol {
    dependencies.favoritesService
  }

  func didLoad() {
    isTrackFavorite = dependencies.favoritesService.contains(track)
    observer = dependencies.favoritesService.addObserverForTracks { [weak self] in
      guard let self else { return }
      isTrackFavorite = dependencies.favoritesService.contains(track)
    }

    let operation = GetEventsByTrack(track: track.name)
    dependencies.persistenceService.performRead(operation) { [weak self] result in
      switch result {
      case let .failure(error):
        self?.didFail.send(error)
      case let .success(events):
        self?.events = events
        self?.captions = events.captions
      }
    }
  }

  func didToggleFavorite() {
    if dependencies.favoritesService.contains(track) {
      dependencies.favoritesService.removeTrack(withIdentifier: track.name)
    } else {
      dependencies.favoritesService.addTrack(withIdentifier: track.name)
    }
  }
}

private extension [Event] {
  var captions: [Event: String] {
    var result: [Event: String] = [:]

    if let event = first, let caption = event.formattedStartWithWeekday {
      result[event] = caption
    }

    for (lhs, rhs) in zip(self, dropFirst()) {
      if lhs.isSameWeekday(as: rhs) {
        if let caption = rhs.formattedStart {
          result[rhs] = caption
        }
      } else {
        if let caption = rhs.formattedStartWithWeekday {
          result[rhs] = caption
        }
      }
    }

    return result
  }
}
