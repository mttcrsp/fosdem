import UIKit

protocol EventsSearchController: UIViewController {
  var results: [Event] { get set }
  var resultsViewController: EventsViewController? { get }
  var persistenceService: PersistenceServiceProtocol { get }
}

extension EventsSearchController {
  func didChangeQuery(_ query: String) {
    guard query.count >= 3 else {
      resultsViewController?.configure(with: .noQuery)
      resultsViewController?.setEvents([])
      return
    }

    let operation = GetEventsBySearch(query: query)
    persistenceService.performRead(operation) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case .failure:
          self?.resultsViewController?.configure(with: .failure(query: query))
          self?.resultsViewController?.setEvents([])
        case let .success(events):
          self?.resultsViewController?.configure(with: .success(query: query))
          self?.resultsViewController?.setEvents(events)
        }
      }
    }
  }
}

private extension EventsViewController {
  enum Configuration {
    case noQuery
    case success(query: String)
    case failure(query: String)
  }

  func configure(with configuration: Configuration) {
    view.isHidden = configuration.isViewHidden
    emptyBackgroundTitle = configuration.emptyBackgroundTitle
    emptyBackgroundMessage = configuration.emptyBackgroundMessage
  }
}

extension EventsViewController.Configuration {
  var emptyBackgroundTitle: String? {
    switch self {
    case .noQuery:
      nil
    case .failure:
      L10n.Search.Error.title
    case .success:
      L10n.Search.Empty.title
    }
  }

  var emptyBackgroundMessage: String? {
    switch self {
    case .noQuery:
      nil
    case .failure:
      L10n.Search.Error.message
    case let .success(query):
      L10n.Search.Empty.message(query)
    }
  }

  var isViewHidden: Bool {
    switch self {
    case .noQuery:
      true
    case .success, .failure:
      false
    }
  }
}
