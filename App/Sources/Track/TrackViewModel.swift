import Combine
import Foundation

final class TrackViewModel {
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
