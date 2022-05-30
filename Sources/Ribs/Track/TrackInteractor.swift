import Foundation
import RIBs

protocol TrackRouting: ViewableRouting {
  func routeToEvent(_ event: Event?)
}

protocol TrackPresentable: Presentable {
  var track: Track? { get set }
  var events: [Event] { get set }
  var showsFavorite: Bool { get set }
}

protocol TrackListener: AnyObject {
  func trackDidError(_ error: Error)
}

final class TrackInteractor: PresentableInteractor<TrackPresentable> {
  weak var router: TrackRouting?
  weak var listener: TrackListener?

  private var observer: NSObjectProtocol?

  private let arguments: TrackArguments
  private let dependency: TrackDependency

  init(arguments: TrackArguments, dependency: TrackDependency, presenter: TrackPresentable) {
    self.arguments = arguments
    self.dependency = dependency
    super.init(presenter: presenter)
  }

  override func didBecomeActive() {
    super.didBecomeActive()

    let track = arguments.track

    presenter.track = track
    presenter.showsFavorite = !dependency.favoritesService.canFavorite(track)
    observer = dependency.favoritesService.addObserverForTracks { [weak self] _ in
      if let self = self {
        self.presenter.showsFavorite = !self.dependency.favoritesService.canFavorite(track)
      }
    }

    let operation = EventsForTrack(track: arguments.track.name)
    dependency.persistenceService.performRead(operation) { [weak self] result in
      DispatchQueue.main.async {
        guard let self = self else { return }

        switch result {
        case let .failure(error):
          self.listener?.trackDidError(error)
        case let .success(events):
          self.presenter.events = events
        }
      }
    }
  }

  override func willResignActive() {
    super.willResignActive()

    if let observer = observer {
      dependency.favoritesService.removeObserver(observer)
    }
  }
}

extension TrackInteractor: TrackPresentableListener {
  func select(_ event: Event) {
    router?.routeToEvent(event)
  }

  func deselectEvent() {
    router?.routeToEvent(nil)
  }

  func canFavorite(_ event: Event) -> Bool {
    dependency.favoritesService.canFavorite(event)
  }

  func toggleFavorite(_ event: Event) {
    dependency.favoritesService.toggleFavorite(event)
  }

  func canFavorite() -> Bool {
    dependency.favoritesService.canFavorite(arguments.track)
  }

  func toggleFavorite() {
    dependency.favoritesService.toggleFavorite(arguments.track)
  }
}
