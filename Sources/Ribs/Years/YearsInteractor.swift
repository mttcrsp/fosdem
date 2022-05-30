import Foundation
import RIBs

protocol YearsPresentable: Presentable {
  var years: [Year] { get set }
  func reloadDownloadState(at index: Int)

  func showError()
  func showNoInternetError(withRetryHandler retryHandler: @escaping () -> Void)
  func showYearUnavailableError()
}

protocol YearsRouting: ViewableRouting {
  func routeToYear(_ year: Year)
}

protocol YearsListener: AnyObject {
  func yearsDidError(_ error: Error)
}

final class YearsInteractor: PresentableInteractor<YearsPresentable> {
  weak var listener: YearsListener?
  weak var router: YearsRouting?

  private var pendingTask: NetworkServiceTask?
  private var pendingYear: Year?

  private let dependency: YearsDependency

  init(presenter: YearsPresentable, dependency: YearsDependency) {
    self.dependency = dependency
    super.init(presenter: presenter)
  }

  override func didBecomeActive() {
    super.didBecomeActive()
    presenter.years = Array(type(of: dependency.yearsService).all).reversed()
  }
}

extension YearsInteractor: YearsPresentableListener {
  func select(_ year: Year) {
    guard let index = presenter.years.firstIndex(of: year) else { return }

    switch downloadState(for: year) {
    case .inProgress:
      break
    case .completed:
      downloadDidSucceed(for: year)
    case .available:
      let task = dependency.yearsService.downloadYear(year) { [weak self] error in
        DispatchQueue.main.async {
          self?.pendingYear = nil
          self?.pendingTask = nil
          self?.presenter.reloadDownloadState(at: index)

          if let error = error {
            self?.downloadDidFail(for: year, with: error)
          } else {
            self?.downloadDidSucceed(for: year)
          }
        }
      }

      pendingYear = year
      pendingTask = task
      presenter.reloadDownloadState(at: index)
    }
  }

  func downloadState(for year: Year) -> YearDownloadState {
    if pendingYear == year {
      return .inProgress
    } else if dependency.yearsService.isYearDownloaded(year) {
      return .completed
    } else {
      return .available
    }
  }
}

extension YearsInteractor: YearsInteractable {
  func yearDidError(_ error: Error) {
    _ = error
  }
}

private extension YearsInteractor {
  func downloadDidSucceed(for year: Year) {
    router?.routeToYear(year)
  }

  func downloadDidFail(for year: Year, with error: Error) {
    switch error {
    case let error as YearsService.Error where error == .yearNotAvailable:
      presenter.showYearUnavailableError()
    case let error as URLError where error.code == .notConnectedToInternet:
      presenter.showNoInternetError(withRetryHandler: { [weak self] in
        self?.select(year)
      })
    default:
      presenter.showError()
    }
  }
}
