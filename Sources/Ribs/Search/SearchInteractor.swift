import Dispatch
import RIBs

protocol SearchPresentable: Presentable {
  var events: [Event] { get set }
  var configuration: SearchPresentableConfiguration { get set }
}

protocol SearchListener: AnyObject {
  func didSelectResult(_ event: Event)
}

final class SearchInteractor: PresentableInteractor<SearchPresentable> {
  weak var listener: SearchListener?

  private let services: SearchServices

  init(presenter: SearchPresentable, services: SearchServices) {
    self.services = services
    super.init(presenter: presenter)
  }
}

extension SearchInteractor: SearchPresentableListener {
  func search(_ query: String) {
    guard query.count >= 3 else {
      presenter.configuration = .noQuery
      presenter.events = []
      return
    }

    let operation = EventsForSearch(query: query)
    services.persistenceService.performRead(operation) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case .failure:
          self?.presenter.configuration = .failure(query: query)
          self?.presenter.events = []
        case let .success(events):
          self?.presenter.configuration = .success(query: query)
          self?.presenter.events = events
        }
      }
    }
  }

  func select(_ event: Event) {
    listener?.didSelectResult(event)
  }

  func canFavorite(_ event: Event) -> Bool {
    services.favoritesService.canFavorite(event)
  }

  func toggleFavorite(_ event: Event) {
    if canFavorite(event) {
      services.favoritesService.addEvent(withIdentifier: event.id)
    } else {
      services.favoritesService.removeEvent(withIdentifier: event.id)
    }
  }
}
