import RIBs
import UIKit

typealias YearsDependency = HasYearBuilder & HasYearsService

protocol YearsListener: AnyObject {
  func yearsDidError(_ error: Error)
}

protocol YearsBuildable: Buildable {
  func build(withListener listener: YearsListener) -> YearsRouting
}

final class YearsBuilder: Builder<YearsDependency>, YearsBuildable {
  func build(withListener listener: YearsListener) -> YearsRouting {
    let viewController = _YearsViewController()
    let interactor = YearsInteractor(presenter: viewController, dependency: dependency)
    let router = YearsRouter(interactor: interactor, viewController: viewController, yearBuilder: dependency.yearBuilder)
    interactor.router = router
    interactor.listener = listener
    viewController.listener = interactor
    return router
  }
}

protocol YearsRouting: ViewableRouting {
  func routeToYear(_ year: Year)
}

final class YearsRouter: ViewableRouter<YearsInteractable, YearsViewControllable> {
  private var yearRouter: ViewableRouting?

  private let yearBuilder: YearBuildable

  init(interactor: YearsInteractable, viewController: YearsViewControllable, yearBuilder: YearBuildable) {
    self.yearBuilder = yearBuilder
    super.init(interactor: interactor, viewController: viewController)
  }
}

extension YearsRouter: YearsRouting {
  func routeToYear(_ year: Year) {
    if let yearRouter = yearRouter {
      detachChild(yearRouter)
      self.yearRouter = nil
    }

    let yearRouter = yearBuilder.build(with: year, listener: interactor)
    self.yearRouter = yearRouter
    attachChild(yearRouter)
    viewController.showYear(yearRouter.viewControllable)
  }
}

protocol YearsInteractable: Interactable, YearListener {}

final class YearsInteractor: PresentableInteractor<YearsPresentable>, YearsInteractable {
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
  func didSelect(_ year: Year) {
    let onFailure: (Error) -> Void = { [weak self] error in
      switch error {
      case let error as URLError where error.code == .notConnectedToInternet:
        self?.presenter.showNoInternetError(withRetryHandler: { [weak self] in
          self?.didSelect(year)
        })
      case let error as YearsService.Error where error == .yearNotAvailable:
        self?.presenter.showYearUnavailableError()
      default:
        self?.presenter.showError()
      }
    }
    let onSuccess: () -> Void = { [weak self] in
      self?.router?.routeToYear(year)
    }

    switch downloadState(for: year) {
    case .inProgress:
      break
    case .completed:
      onSuccess()
    case .available:
      let task = dependency.yearsService.downloadYear(year) { [weak self] error in
        DispatchQueue.main.async {
          if let error = error {
            onFailure(error)
          } else {
            onSuccess()
          }

          self?.pendingYear = nil
          self?.pendingTask = nil
          self?.presenter.reloadData()
        }
      }

      pendingYear = year
      pendingTask = task
      presenter.reloadData()
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

  func yearDidError(_ error: Error) {
    _ = error
  }
}

protocol YearsViewControllable: ViewControllable {
  func showYear(_ yearViewControllable: ViewControllable)
}

protocol YearsPresentable: Presentable {
  var years: [Year] { get set }
  func reloadData()
  func showYearUnavailableError()
  func showNoInternetError(withRetryHandler retryHandler: @escaping () -> Void)
  func showError()
}

protocol YearsPresentableListener: AnyObject {
  func didSelect(_ year: Year)
  func downloadState(for year: Year) -> YearDownloadState
}

final class _YearsViewController: YearsViewController, YearsPresentable, YearsViewControllable {
  weak var listener: YearsPresentableListener?

  var years: [Year] = []

  init() {
    super.init(style: {
      if UIDevice.current.userInterfaceIdiom == .pad {
        return .fos_insetGrouped
      } else {
        return .grouped
      }
    }())
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension _YearsViewController {
  override func viewDidLoad() {
    super.viewDidLoad()

    delegate = self
    dataSource = self
    title = L10n.Years.title
  }
}

extension _YearsViewController: YearsViewControllerDataSource, YearsViewControllerDelegate {
  func reloadData() {
    tableView.reloadData()
  }

  func showYear(_ yearViewControllable: ViewControllable) {
    let yearViewController = yearViewControllable.uiviewController
    show(yearViewController, sender: nil)
  }

  func numberOfYears(in _: YearsViewController) -> Int {
    years.count
  }

  func yearsViewController(_: YearsViewController, yearAt index: Int) -> Year {
    years[index]
  }

  func yearsViewController(_: YearsViewController, downloadStateAt index: Int) -> YearDownloadState {
    listener?.downloadState(for: years[index]) ?? .available
  }

  func yearsViewController(_: YearsViewController, didSelectYearAt index: Int) {
    listener?.didSelect(years[index])
  }

  func showYearUnavailableError() {
    let title = L10n.Years.Unavailable.title, message = L10n.Years.Unavailable.message
    let errorViewController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    errorViewController.addAction(.init(title: L10n.Years.Unavailable.dismiss, style: .default))
    present(errorViewController, animated: true)
  }

  func showNoInternetError(withRetryHandler retryHandler: @escaping () -> Void) {
    let errorViewController = UIAlertController.makeNoInternetController(withRetryHandler: retryHandler)
    present(errorViewController, animated: true)
  }

  func showError() {
    let errorViewController = UIAlertController.makeErrorController()
    present(errorViewController, animated: true)
  }
}
