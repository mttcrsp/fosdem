import Dispatch
import RIBs

protocol SearchPresentable: Presentable {
  var events: [Event] { get set }
  var allowsFavoriting: Bool { get set }
  var configuration: SearchPresentableConfiguration { get set }
}

protocol SearchListener: AnyObject {
  func didSelectResult(_ event: Event)
}

final class SearchInteractor: PresentableInteractor<SearchPresentable> {
  weak var listener: SearchListener?

  private let arguments: SearchArguments

  init(arguments: SearchArguments, presenter: SearchPresentable) {
    self.arguments = arguments
    super.init(presenter: presenter)
  }

  override func didBecomeActive() {
    super.didBecomeActive()
    presenter.allowsFavoriting = arguments.favoritesService != nil
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
    arguments.persistenceService.performRead(operation) { [weak self] result in
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
    arguments.favoritesService?.canFavorite(event) ?? false
  }

  func toggleFavorite(_ event: Event) {
    guard let favoritesService = arguments.favoritesService else { return }

    if canFavorite(event) {
      favoritesService.addEvent(withIdentifier: event.id)
    } else {
      favoritesService.removeEvent(withIdentifier: event.id)
    }
  }
}
