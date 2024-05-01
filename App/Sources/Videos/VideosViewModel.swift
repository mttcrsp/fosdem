import Combine
import Foundation

final class VideosViewModel {
  typealias Dependencies = HasPlaybackService & HasVideosService

  private let dependencies: Dependencies
  private(set) var observer: NSObjectProtocol?
  @Published private(set) var watchedEvents: [Event] = []
  @Published private(set) var watchingEvents: [Event] = []
  let didFail = PassthroughSubject<Error, Never>()

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
  }

  func didLoad() {
    loadVideos()
    observer = dependencies.playbackService.addObserver { [weak self] in
      self?.loadVideos()
    }
  }

  func didUnload() {
    if let observer {
      dependencies.playbackService.removeObserver(observer)
    }
  }

  func didDelete(_ event: Event) {
    dependencies.playbackService.setPlaybackPosition(.beginning, forEventWithIdentifier: event.id)
  }
}

private extension VideosViewModel {
  func loadVideos() {
    dependencies.videosService.loadVideos { [weak self] result in
      switch result {
      case let .success(videos):
        self?.watchedEvents = videos.watched
        self?.watchingEvents = videos.watching
      case let .failure(error):
        self?.didFail.send(error)
      }
    }
  }
}
