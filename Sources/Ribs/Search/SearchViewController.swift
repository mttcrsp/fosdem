import RIBs
import UIKit

enum SearchPresentableConfiguration {
  case noQuery
  case success(query: String)
  case failure(query: String)
}

protocol SearchPresentableListener: AnyObject {
  func search(_ query: String)
  func select(_ event: Event)
  func toggleFavorite(_ event: Event)
  func canFavorite(_ event: Event) -> Bool
}

final class SearchViewController: UISearchController, ViewControllable, SearchPresentable {
  weak var listener: SearchPresentableListener?

  var events: [Event] = [] {
    didSet { eventsViewController?.reloadData() }
  }

  var configuration: SearchPresentableConfiguration = .noQuery {
    didSet { didChangeConfiguration() }
  }

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

    listener?.select(event)

    if traitCollection.horizontalSizeClass == .regular {
      searchBar.endEditing(true)
    }
  }
}

extension SearchViewController: EventsViewControllerFavoritesDataSource {
  func eventsViewController(_: EventsViewController, canFavorite event: Event) -> Bool {
    listener?.canFavorite(event) ?? false
  }
}

extension SearchViewController: EventsViewControllerFavoritesDelegate {
  func eventsViewController(_: EventsViewController, didToggleFavorite event: Event) {
    listener?.toggleFavorite(event)
  }
}

extension SearchViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    listener?.search(searchController.searchBar.text ?? "")
  }
}

private extension SearchViewController {
  func didChangeConfiguration() {
    eventsViewController?.view.isHidden = configuration.isViewHidden
    eventsViewController?.emptyBackgroundTitle = configuration.emptyBackgroundTitle
    eventsViewController?.emptyBackgroundMessage = configuration.emptyBackgroundMessage
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
