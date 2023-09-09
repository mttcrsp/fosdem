import Dispatch

struct VideosClient {
  struct Videos: Equatable {
    let watching, watched: [Event]
  }

  var loadVideos: (@escaping (Result<Videos, Error>) -> Void) -> Void
}

extension VideosClient {
  init(playbackClient: PlaybackClientProtocol, persistenceClient: PersistenceClientProtocol) {
    loadVideos = { completion in
      let group = DispatchGroup()
      var groupError: Error?
      var watching: [Event]?
      var watched: [Event]?

      group.enter()
      persistenceClient.eventsByIdentifier(playbackClient.watched()) { result in
        switch result {
        case let .failure(error):
          groupError = groupError ?? error
        case let .success(events):
          watched = events
        }
        group.leave()
      }

      group.enter()
      persistenceClient.eventsByIdentifier(playbackClient.watching()) { result in
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
}

/// @mockable
protocol VideosClientProtocol {
  var loadVideos: (@escaping (Result<VideosClient.Videos, Error>) -> Void) -> Void { get }
}

extension VideosClient: VideosClientProtocol {}
