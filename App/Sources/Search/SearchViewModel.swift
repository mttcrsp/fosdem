import Combine

struct SearchResultsConfiguration {
  var configurationType: SearchResultsConfigurationType
  var results: [Event] = []
  var query: String = ""
}

enum SearchResultsConfigurationType {
  case noQuery, success, failure
}

final class SearchViewModel {
  @Published private(set) var configuration = SearchResultsConfiguration(configurationType: .noQuery)
  private let persistenceService: PersistenceServiceProtocol

  init(persistenceService: PersistenceServiceProtocol) {
    self.persistenceService = persistenceService
  }

  func didChangeQuery(_ query: String) {
    guard query.count >= 3 else {
      configuration = .init(configurationType: .noQuery)
      return
    }

    persistenceService.performRead(GetEventsBySearch(query: query)) { [weak self] result in
      guard let self else { return }

      switch result {
      case .failure:
        var configuration = SearchResultsConfiguration(configurationType: .failure)
        configuration.query = query
        configuration.results = []
        self.configuration = configuration
      case let .success(events):
        var configuration = SearchResultsConfiguration(configurationType: .success)
        configuration.query = query
        configuration.results = events
        self.configuration = configuration
      }
    }
  }
}

extension EventsViewController {
  func configure(with configuration: SearchResultsConfiguration) {
    view.isHidden = configuration.isViewHidden
    emptyBackgroundTitle = configuration.emptyBackgroundTitle
    emptyBackgroundMessage = configuration.emptyBackgroundMessage
  }
}

private extension SearchResultsConfiguration {
  var emptyBackgroundTitle: String? {
    switch configurationType {
    case .noQuery: nil
    case .failure: L10n.Search.Error.title
    case .success: L10n.Search.Empty.title
    }
  }

  var emptyBackgroundMessage: String? {
    switch configurationType {
    case .noQuery: nil
    case .failure: L10n.Search.Error.message
    case .success: L10n.Search.Empty.message(query)
    }
  }

  var isViewHidden: Bool {
    switch configurationType {
    case .noQuery: true
    case .success, .failure: false
    }
  }
}
