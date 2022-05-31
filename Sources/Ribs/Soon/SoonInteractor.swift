import Foundation
import RIBs

protocol SoonRouting: ViewableRouting {
  func routeToEvent(_ event: Event?)
}

protocol SoonPresentable: Presentable {
  var events: [Event] { get set }
}

protocol SoonListener: AnyObject {
  func soonDidError(_ error: Error)
  func soonDidDismiss()
}

final class SoonInteractor: PresentableInteractor<SoonPresentable> {
  weak var router: SoonRouting?
  weak var listener: SoonListener?

  private let services: SoonServices

  init(services: SoonServices, presenter: SoonPresentable) {
    self.services = services
    super.init(presenter: presenter)
  }

  override func didBecomeActive() {
    super.didBecomeActive()

    services.soonService.loadEvents { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case let .failure(error):
          self?.listener?.soonDidError(error)
        case let .success(events):
          self?.presenter.events = events
        }
      }
    }
  }
}

extension SoonInteractor: SoonPresentableListener {
  func select(_ event: Event?) {
    router?.routeToEvent(event)
  }

  func canFavorite(_ event: Event) -> Bool {
    services.favoritesService.canFavorite(event)
  }

  func toggleFavorite(_ event: Event) {
    services.favoritesService.toggleFavorite(event)
  }

  func dismiss() {
    listener?.soonDidDismiss()
  }
}
