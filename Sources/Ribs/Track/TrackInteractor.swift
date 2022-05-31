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
  private let services: TrackServices

  init(arguments: TrackArguments, presenter: TrackPresentable, services: TrackServices) {
    self.arguments = arguments
    self.services = services
    super.init(presenter: presenter)
  }

  override func didBecomeActive() {
    super.didBecomeActive()

    let track = arguments.track

    presenter.track = track
    presenter.showsFavorite = !services.favoritesService.canFavorite(track)
    observer = services.favoritesService.addObserverForTracks { [weak self] _ in
      if let self = self {
        self.presenter.showsFavorite = !self.services.favoritesService.canFavorite(track)
      }
    }

    let operation = EventsForTrack(track: track.name)
    services.persistenceService.performRead(operation) { [weak self] result in
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
      services.favoritesService.removeObserver(observer)
    }
  }
}

extension TrackInteractor: TrackPresentableListener {
  func select(_ event: Event?) {
    router?.routeToEvent(event)
  }

  func canFavorite(_ event: Event) -> Bool {
    services.favoritesService.canFavorite(event)
  }

  func toggleFavorite(_ event: Event) {
    services.favoritesService.toggleFavorite(event)
  }

  func canFavorite() -> Bool {
    services.favoritesService.canFavorite(arguments.track)
  }

  func toggleFavorite() {
    services.favoritesService.toggleFavorite(arguments.track)
  }
}
