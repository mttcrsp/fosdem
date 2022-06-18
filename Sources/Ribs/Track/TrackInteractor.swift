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
  private let component: TrackComponent

  init(arguments: TrackArguments, component: TrackComponent, presenter: TrackPresentable) {
    self.arguments = arguments
    self.component = component
    super.init(presenter: presenter)
  }

  override func didBecomeActive() {
    super.didBecomeActive()

    let track = arguments.track

    presenter.track = track
    presenter.showsFavorite = !component.favoritesService.canFavorite(track)
    observer = component.favoritesService.addObserverForTracks { [weak self] _ in
      if let self = self {
        self.presenter.showsFavorite = !self.component.favoritesService.canFavorite(track)
      }
    }

    let operation = EventsForTrack(track: track.name)
    component.persistenceService.performRead(operation) { [weak self] result in
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
      component.favoritesService.removeObserver(observer)
    }
  }
}

extension TrackInteractor: TrackPresentableListener {
  func select(_ event: Event?) {
    router?.routeToEvent(event)
  }

  func canFavorite(_ event: Event) -> Bool {
    component.favoritesService.canFavorite(event)
  }

  func toggleFavorite(_ event: Event) {
    component.favoritesService.toggleFavorite(event)
  }

  func canFavorite() -> Bool {
    component.favoritesService.canFavorite(arguments.track)
  }

  func toggleFavorite() {
    component.favoritesService.toggleFavorite(arguments.track)
  }
}
