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

  private let component: SoonComponent

  init(component: SoonComponent, presenter: SoonPresentable) {
    self.component = component
    super.init(presenter: presenter)
  }

  override func didBecomeActive() {
    super.didBecomeActive()

    component.soonService.loadEvents { [weak self] result in
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
    component.favoritesService.canFavorite(event)
  }

  func toggleFavorite(_ event: Event) {
    component.favoritesService.toggleFavorite(event)
  }

  func dismiss() {
    listener?.soonDidDismiss()
  }
}
