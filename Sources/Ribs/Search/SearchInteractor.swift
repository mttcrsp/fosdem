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

  private let dependency: SearchDependency

  init(presenter: SearchPresentable, dependency: SearchDependency) {
    self.dependency = dependency
    super.init(presenter: presenter)
  }
}

extension SearchInteractor: SearchPresentableListener {
  func searchEvents(for query: String) {
    guard query.count >= 3 else {
      presenter.configuration = .noQuery
      presenter.events = []
      return
    }

    let operation = EventsForSearch(query: query)
    dependency.persistenceService.performRead(operation) { [weak self] result in
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

  func selectEvent(_ event: Event) {
    listener?.didSelectResult(event)
  }

  func canFavoriteEvent(_ event: Event) -> Bool {
    !dependency.favoritesService.contains(event)
  }

  func toggleFavorite(_ event: Event) {
    if canFavoriteEvent(event) {
      dependency.favoritesService.addEvent(withIdentifier: event.id)
    } else {
      dependency.favoritesService.removeEvent(withIdentifier: event.id)
    }
  }
}
