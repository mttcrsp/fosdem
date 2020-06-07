import UIKit

protocol EventsSearchController: UIViewController {
  var results: [Event] { get set }
  var resultsViewController: EventsViewController? { get }
  var persistenceService: PersistenceService { get }
}

extension EventsSearchController {
  func didChangeQuery(_ query: String) {
    guard query.count >= 3 else {
      results = []
      resultsViewController?.configure(with: .noQuery)
      resultsViewController?.reloadData()
      return
    }

    let operation = EventsForSearch(query: query)
    persistenceService.performRead(operation) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case .failure:
          self?.results = []
          self?.resultsViewController?.configure(with: .failure(query: query))
          self?.resultsViewController?.reloadData()
        case let .success(events):
          self?.results = events
          self?.resultsViewController?.configure(with: .success(query: query))
          self?.resultsViewController?.reloadData()
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
      return nil
    case .failure:
      return NSLocalizedString("search.error.title", comment: "")
    case .success:
      return NSLocalizedString("search.empty.title", comment: "")
    }
  }

  var emptyBackgroundMessage: String? {
    switch self {
    case .noQuery:
      return nil
    case .failure:
      return NSLocalizedString("search.error.message", comment: "")
    case let .success(query):
      let format = NSLocalizedString("search.empty.message", comment: "")
      let string = String(format: format, query)
      return string
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
