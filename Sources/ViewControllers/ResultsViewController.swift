import UIKit

typealias ResultsViewController = EventsViewController

extension EventsViewController {
  enum Configuration {
    case noQuery
    case success(query: String)
    case failure(query: String)
  }

  func configure(with configuration: Configuration) {
    emptyBackgroundMessage = configuration.emptyBackgroundMessage
    emptyBackgroundTitle = configuration.emptyBackgroundTitle
    view.isHidden = configuration.isViewHidden
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
