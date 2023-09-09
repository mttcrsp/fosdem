import Dispatch

final class VideosService {
  struct Videos: Equatable {
    let watching, watched: [Event]
  }

  private let playbackService: PlaybackServiceProtocol
  private let persistenceService: PersistenceServiceProtocol

  init(playbackService: PlaybackServiceProtocol, persistenceService: PersistenceServiceProtocol) {
    self.playbackService = playbackService
    self.persistenceService = persistenceService
  }

  func loadVideos(_ completion: @escaping (Result<Videos, Error>) -> Void) {
    let group = DispatchGroup()
    var groupError: Error?
    var watching: [Event]?
    var watched: [Event]?

    group.enter()
    let watchedIdentifiers = playbackService.watched()
    let watchedOperation = GetEventsByIdentifiers(identifiers: watchedIdentifiers)
    persistenceService.performRead(watchedOperation) { result in
      switch result {
      case let .failure(error):
        groupError = groupError ?? error
      case let .success(events):
        watched = events
      }
      group.leave()
    }

    group.enter()
    let watchingIdentifiers = playbackService.watching()
    let watchingOperation = GetEventsByIdentifiers(identifiers: watchingIdentifiers)
    persistenceService.performRead(watchingOperation) { result in
      switch result {
      case let .failure(error):
        groupError = groupError ?? error
      case let .success(events):
        watching = events
      }
      group.leave()
    }

    group.notify(queue: .main) {
      if let error = groupError {
        completion(.failure(error))
      } else if let watching = watching, let watched = watched {
        completion(.success(Videos(watching: watching, watched: watched)))
      }
    }
  }
}

/// @mockable
protocol VideosServiceProtocol {
  func loadVideos(_ completion: @escaping (Result<VideosService.Videos, Error>) -> Void)
}

extension VideosService: VideosServiceProtocol {}

protocol HasVideosService {
  var videosService: VideosServiceProtocol { get }
}
