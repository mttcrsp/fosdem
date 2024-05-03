import Combine

final class YearViewModel {
  let didFail = PassthroughSubject<Error, Never>()
  @Published private(set) var tracks: [Track] = []
  @Published private(set) var events: [Event] = []
  private let persistenceService: PersistenceServiceProtocol

  init(persistenceService: PersistenceServiceProtocol) {
    self.persistenceService = persistenceService
  }

  func didLoad() {
    persistenceService.performRead(GetAllTracks()) { [weak self] result in
      switch result {
      case let .failure(error):
        self?.didFail.send(error)
      case let .success(tracks):
        self?.tracks = tracks
      }
    }
  }

  func didSelectTrack(_ track: Track) {
    events = []
    persistenceService.performRead(GetEventsByTrack(track: track.name)) { [weak self] result in
      switch result {
      case let .failure(error):
        self?.didFail.send(error)
      case let .success(events):
        self?.events = events
      }
    }
  }
}
