import UIKit

final class YearsController: YearsViewController {
  typealias Dependencies = HasYearsService & HasNavigationService

  var didError: ((UIViewController, Error) -> Void)?

  private(set) var yearsPendingTasks: [Year: NetworkServiceTask] = [:]

  private let dependencies: Dependencies

  init(style: UITableView.Style, dependencies: Dependencies) {
    self.dependencies = dependencies
    super.init(style: style)

    delegate = self
    dataSource = self
    title = L10n.Years.title
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

private extension YearsController {
  func makeYearUnavailableViewController() -> UIAlertController {
    let title = L10n.Years.Unavailable.title, message = L10n.Years.Unavailable.message
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alertController.addAction(.init(title: L10n.Years.Unavailable.dismiss, style: .default))
    return alertController
  }

  func makeErrorViewController(withHandler handler: (() -> Void)? = nil) -> UIAlertController {
    UIAlertController.makeErrorController(withHandler: handler)
  }

  func makeYearViewController(forYear year: Int, with persistenceService: PersistenceServiceProtocol, didError: @escaping NavigationService.ErrorHandler) -> UIViewController {
    dependencies.navigationService.makeYearsViewController(forYear: year, with: persistenceService, didError: didError)
  }
}

extension YearsController: YearsViewControllerDataSource, YearsViewControllerDelegate {
  private var years: [Year] {
    Array(type(of: dependencies.yearsService).all).reversed()
  }

  private func downloadState(for year: Year) -> YearDownloadState {
    if yearsPendingTasks[year] != nil {
      return .inProgress
    } else if dependencies.yearsService.isYearDownloaded(year) {
      return .completed
    } else {
      return .available
    }
  }

  func numberOfYears(in _: YearsViewController) -> Int {
    years.count
  }

  func yearsViewController(_: YearsViewController, yearAt index: Int) -> Year {
    years[index]
  }

  func yearsViewController(_: YearsViewController, downloadStateAt index: Int) -> YearDownloadState {
    downloadState(for: years[index])
  }

  func yearsViewController(_ yearsViewController: YearsViewController, didSelectYearAt index: Int) {
    let year = years[index]

    let onYearDownloadFailure: (Error) -> Void = { [weak self, weak yearsViewController] error in
      if let self = self, let yearsViewController = yearsViewController {
        self.yearsViewController(yearsViewController, loadingDidFailWith: error)
      }
    }

    let onYearDownloadSuccess = { [weak self, weak yearsViewController] in
      if let self = self, let yearsViewController = yearsViewController {
        self.yearsViewController(yearsViewController, loadingDidSucceedFor: year)
      }
    }

    let cancelTask = { [weak self, weak yearsViewController] in
      self?.yearsPendingTasks[year]?.cancel()
      self?.yearsPendingTasks[year] = nil
      yearsViewController?.reloadRow(at: index)
    }

    let onYearDownloaded: (Error?) -> Void = { error in
      DispatchQueue.main.async {
        cancelTask()
        if let error = error {
          onYearDownloadFailure(error)
        } else {
          onYearDownloadSuccess()
        }
      }
    }

    switch downloadState(for: year) {
    case .completed:
      onYearDownloadSuccess()
    case .inProgress:
      cancelTask()
    case .available:
      UIAccessibility.post(notification: .announcement, argument: L10n.Years.progress)
      yearsPendingTasks[year] = dependencies.yearsService.downloadYear(year, completion: onYearDownloaded)
      yearsViewController.reloadRow(at: index)
    }
  }

  func yearsViewController(_ yearsViewController: YearsViewController, loadingDidSucceedFor year: Int) {
    do {
      let didError: (UIViewController, Error) -> Void = { [weak self] viewController, error in
        self?.didError?(viewController, error)
      }
      let persistenceService = try dependencies.yearsService.makePersistenceService(forYear: year)
      let yearViewController = makeYearViewController(forYear: year, with: persistenceService, didError: didError)
      yearsViewController.show(yearViewController, sender: nil)
    } catch {
      self.yearsViewController(yearsViewController, loadingDidFailWith: error)
    }
  }

  func yearsViewController(_ yearsViewController: YearsViewController, loadingDidFailWith error: Error) {
    switch error {
    case let error as YearsService.Error where error == .yearNotAvailable:
      let unavailableViewController = makeYearUnavailableViewController()
      yearsViewController.present(unavailableViewController, animated: true)
    default:
      let errorViewController = makeErrorViewController()
      yearsViewController.present(errorViewController, animated: true)
    }
  }
}
