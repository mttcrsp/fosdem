import RIBs
import UIKit

typealias SearchDependency = HasFavoritesService & HasPersistenceService

protocol SearchListener: AnyObject {
  func didSelectResult(_ event: Event)
}

protocol SearchBuildable: Buildable {
  func build(withListener listener: SearchListener) -> ViewableRouting
}

final class SearchBuilder: Builder<SearchDependency>, SearchBuildable {
  func build(withListener listener: SearchListener) -> ViewableRouting {
    let viewController = SearchViewController()
    let interactor = SearchInteractor(presenter: viewController, dependency: dependency)
    let router = SearchRouter(interactor: interactor, viewController: viewController)
    interactor.listener = listener
    viewController.listener = interactor
    return router
  }
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
  func didChangeQuery(_ query: String) {
    guard query.count >= 3 else {
      presenter.setEvents([], configuration: .noQuery)
      return
    }

    let operation = EventsForSearch(query: query)
    dependency.persistenceService.performRead(operation) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case .failure:
          self?.presenter.setEvents([], configuration: .failure(query: query))
        case let .success(events):
          self?.presenter.setEvents(events, configuration: .success(query: query))
        }
      }
    }
  }

  func didSelectEvent(_ event: Event) {
    listener?.didSelectResult(event)
  }

  func canFavoritEvent(_ event: Event) -> Bool {
    !dependency.favoritesService.contains(event)
  }

  func toggleFavorite(_ event: Event) {
    if canFavoritEvent(event) {
      dependency.favoritesService.addEvent(withIdentifier: event.id)
    } else {
      dependency.favoritesService.removeEvent(withIdentifier: event.id)
    }
  }
}

final class SearchRouter: ViewableRouter<Interactable, ViewControllable> {}

protocol SearchPresentable: Presentable {
  func setEvents(_ events: [Event], configuration: SearchPresentableConfiguration)
}

enum SearchPresentableConfiguration {
  case noQuery
  case success(query: String)
  case failure(query: String)
}

protocol SearchPresentableListener: AnyObject {
  func didChangeQuery(_ query: String)
  func didSelectEvent(_ event: Event)
  func toggleFavorite(_ event: Event)
  func canFavoritEvent(_ event: Event) -> Bool
}

final class SearchViewController: UISearchController, ViewControllable {
  weak var listener: SearchPresentableListener?

  private var events: [Event] = []

  private weak var eventsViewController: EventsViewController?

  init() {
    let eventsViewController = EventsViewController(style: .grouped)
    super.init(searchResultsController: eventsViewController)

    searchBar.placeholder = L10n.More.Search.prompt
    searchResultsUpdater = self

    eventsViewController.favoritesDataSource = self
    eventsViewController.favoritesDelegate = self
    eventsViewController.dataSource = self
    eventsViewController.delegate = self
    self.eventsViewController = eventsViewController
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension SearchViewController: SearchPresentable {
  func setEvents(_ events: [Event], configuration: SearchPresentableConfiguration) {
    self.events = events
    eventsViewController?.view.isHidden = configuration.isViewHidden
    eventsViewController?.emptyBackgroundTitle = configuration.emptyBackgroundTitle
    eventsViewController?.emptyBackgroundMessage = configuration.emptyBackgroundMessage
    eventsViewController?.reloadData()
  }
}

extension SearchViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    listener?.didChangeQuery(searchController.searchBar.text ?? "")
  }
}

extension SearchViewController: EventsViewControllerDataSource {
  func events(in _: EventsViewController) -> [Event] {
    events
  }

  func eventsViewController(_: EventsViewController, captionFor event: Event) -> String? {
    event.track
  }
}

extension SearchViewController: EventsViewControllerDelegate {
  func eventsViewController(_ eventsViewController: EventsViewController, didSelect event: Event) {
    eventsViewController.deselectSelectedRow(animated: true)

    listener?.didSelectEvent(event)

    if traitCollection.horizontalSizeClass == .regular {
      searchBar.endEditing(true)
    }
  }
}

extension SearchViewController: EventsViewControllerFavoritesDataSource {
  func eventsViewController(_: EventsViewController, canFavorite event: Event) -> Bool {
    listener?.canFavoritEvent(event) ?? false
  }
}

extension SearchViewController: EventsViewControllerFavoritesDelegate {
  func eventsViewController(_: EventsViewController, didToggleFavorite event: Event) {
    listener?.toggleFavorite(event)
  }
}

private extension SearchPresentableConfiguration {
  var emptyBackgroundTitle: String? {
    switch self {
    case .noQuery:
      return nil
    case .failure:
      return L10n.Search.Error.title
    case .success:
      return L10n.Search.Empty.title
    }
  }

  var emptyBackgroundMessage: String? {
    switch self {
    case .noQuery:
      return nil
    case .failure:
      return L10n.Search.Error.message
    case let .success(query):
      return L10n.Search.Empty.message(query)
    }
  }

  var isViewHidden: Bool {
    switch self {
    case .noQuery:
      return true
    case .success, .failure:
      return false
    }
  }
}
