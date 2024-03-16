import UIKit

final class YearsController: YearsViewController {
  typealias Dependencies = HasNavigationService & HasYearsService

  var didError: ((UIViewController, Error) -> Void)?

  private var pendingYear: Year?
  private var pendingTask: NetworkServiceTask?

  private let dependencies: Dependencies

  init(style: UITableView.Style, dependencies: Dependencies) {
    self.dependencies = dependencies
    super.init(style: style)
  }

  deinit {
    pendingTask?.cancel()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    delegate = self
    dataSource = self
    title = L10n.Years.title
  }
}

extension YearsController: YearsViewControllerDataSource, YearsViewControllerDelegate {
  private var years: [Year] {
    Array(type(of: dependencies.yearsService).all).reversed()
  }

  private func downloadState(for year: Year) -> YearDownloadState {
    if pendingYear == year {
      .inProgress
    } else if dependencies.yearsService.isYearDownloaded(year) {
      .completed
    } else {
      .available
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

    let onRetry: () -> Void = { [weak self, weak yearsViewController] in
      if let self, let yearsViewController {
        self.yearsViewController(yearsViewController, didSelectYearAt: index)
      }
    }
    let onFailure: (Error) -> Void = { [weak self, weak yearsViewController] error in
      if let self, let yearsViewController {
        self.yearsViewController(yearsViewController, loadingDidFailWith: error, retryHandler: onRetry)
      }
    }
    let onSuccess: () -> Void = { [weak self, weak yearsViewController] in
      if let self, let yearsViewController {
        self.yearsViewController(yearsViewController, loadingDidSucceedFor: year, retryHandler: onRetry)
      }
    }

    switch downloadState(for: year) {
    case .inProgress:
      break
    case .completed:
      onSuccess()
    case .available:
      let task = dependencies.yearsService.downloadYear(year) { [weak self, weak yearsViewController] error in
        DispatchQueue.main.async {
          if let error {
            onFailure(error)
          } else {
            onSuccess()
          }

          self?.pendingYear = nil
          self?.pendingTask = nil
          yearsViewController?.allowsSelection = true
          yearsViewController?.reloadDownloadState(at: index)
        }
      }

      pendingYear = year
      pendingTask = task
      yearsViewController.allowsSelection = false
      yearsViewController.reloadDownloadState(at: index)
      yearsViewController.deselectSelectedRow(animated: true)
    }
  }

  func yearsViewController(_ yearsViewController: YearsViewController, loadingDidSucceedFor year: Int, retryHandler: @escaping () -> Void) {
    do {
      let persistenceService = try dependencies.yearsService.makePersistenceService(forYear: year)
      let yearViewController = makeYearViewController(forYear: year, with: persistenceService)
      yearsViewController.show(yearViewController, sender: nil)
    } catch {
      self.yearsViewController(yearsViewController, loadingDidFailWith: error, retryHandler: retryHandler)
    }
  }

  func yearsViewController(_ yearsViewController: YearsViewController, loadingDidFailWith error: Error, retryHandler: @escaping () -> Void) {
    switch error {
    case let error as YearsService.Error where error == .yearNotAvailable:
      let errorViewController = makeYearUnavailableViewController()
      yearsViewController.present(errorViewController, animated: true)
    case let error as URLError where error.code == .notConnectedToInternet:
      let errorViewController = UIAlertController.makeNoInternetController(withRetryHandler: retryHandler)
      yearsViewController.present(errorViewController, animated: true)
    default:
      let errorViewController = UIAlertController.makeErrorController()
      yearsViewController.present(errorViewController, animated: true)
    }
  }
}

private extension YearsController {
  func makeYearViewController(forYear year: Int, with persistenceService: PersistenceServiceProtocol) -> UIViewController {
    let yearViewController = dependencies.navigationService.makeYearViewController(for: persistenceService)
    yearViewController.title = year.description
    yearViewController.navigationItem.largeTitleDisplayMode = .never
    yearViewController.didError = { [weak self] viewController, error in
      self?.didError?(viewController, error)
    }
    return yearViewController
  }

  func makeYearUnavailableViewController() -> UIAlertController {
    let title = L10n.Years.Unavailable.title, message = L10n.Years.Unavailable.message
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alertController.addAction(.init(title: L10n.Years.Unavailable.dismiss, style: .default))
    return alertController
  }
}
