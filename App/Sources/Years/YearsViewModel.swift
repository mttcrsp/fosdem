import Combine

typealias Year = Int

enum YearDownloadState: CaseIterable {
  case available, inProgress, completed
}

enum YearLoadingState {
  case idle
  case loading(Year, NetworkServiceTask)
  case success(Year, PersistenceServiceProtocol)
  case failure(Year, Error)
}

final class YearsViewModel {
  typealias Dependencies = HasYearsService

  @Published private(set) var loadingState = YearLoadingState.idle
  @Published private(set) var years: [Year] = []

  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
  }

  func didLoad() {
    years = Array(type(of: dependencies.yearsService).all).reversed()
  }

  func didUnload() {
    if case let .loading(_, task) = loadingState {
      task.cancel()
    }
  }

  func downloadState(for year: Year) -> YearDownloadState {
    if case .loading(year, _) = loadingState {
      .inProgress
    } else if dependencies.yearsService.isYearDownloaded(year) {
      .completed
    } else {
      .available
    }
  }

  func didSelect(_ year: Year) {
    switch downloadState(for: year) {
    case .inProgress:
      break
    case .completed:
      onLoadingSuccess(year)
    case .available:
      let task = dependencies.yearsService.downloadYear(year) { [weak self] error in
        if let error {
          self?.onLoadingFailure(year, error)
        } else {
          self?.onLoadingSuccess(year)
        }
      }

      loadingState = .loading(year, task)
    }
  }
}

private extension YearsViewModel {
  func onLoadingSuccess(_ year: Year) {
    do {
      let persistenceService = try dependencies.yearsService.makePersistenceService(forYear: year)
      loadingState = .success(year, persistenceService)
      loadingState = .idle
    } catch {
      onLoadingFailure(year, error)
    }
  }

  func onLoadingFailure(_ year: Year, _ error: Error) {
    loadingState = .failure(year, error)
    loadingState = .idle
  }
}
