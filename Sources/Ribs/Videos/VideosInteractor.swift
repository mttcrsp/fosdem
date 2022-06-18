import Foundation
import RIBs

protocol VideosListener: AnyObject {
  func videosDidError(_ error: Error)
  func videosDidDismiss()
}

protocol VideosRouting: ViewableRouting {
  func routeToEvent(_ event: Event?)
}

protocol VideosPresentable: Presentable {
  var watchedEvents: [Event] { get set }
  var watchingEvents: [Event] { get set }
}

final class VideosInteractor: PresentableInteractor<VideosPresentable> {
  weak var listener: VideosListener?
  weak var router: VideosRouting?

  private var observer: NSObjectProtocol?

  private let component: VideosComponent

  init(component: VideosComponent, presenter: VideosPresentable) {
    self.component = component
    super.init(presenter: presenter)
  }

  override func didBecomeActive() {
    super.didBecomeActive()

    loadVideos()
    observer = component.playbackService.addObserver { [weak self] in
      self?.loadVideos()
    }
  }

  override func willResignActive() {
    super.willResignActive()

    if let observer = observer {
      component.playbackService.removeObserver(observer)
    }
  }
}

extension VideosInteractor: VideosPresentableListener {
  func delete(_ event: Event) {
    component.playbackService.setPlaybackPosition(.beginning, forEventWithIdentifier: event.id)
  }

  func select(_ event: Event) {
    router?.routeToEvent(event)
  }

  func deselectEvent() {
    router?.routeToEvent(nil)
  }
}

private extension VideosInteractor {
  func loadVideos() {
    component.videosService.loadVideos { [weak self] result in
      switch result {
      case let .failure(error):
        self?.listener?.videosDidError(error)
      case let .success(videos):
        self?.presenter.watchedEvents = videos.watched
        self?.presenter.watchingEvents = videos.watching
      }
    }
  }
}
