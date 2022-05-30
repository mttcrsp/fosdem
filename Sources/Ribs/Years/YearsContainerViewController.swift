import RIBs
import UIKit

protocol YearsPresentableListener: AnyObject {
  func select(_ year: Year)
  func downloadState(for year: Year) -> YearDownloadState
}

final class YearsContainerViewController: YearsViewController {
  weak var listener: YearsPresentableListener?

  var years: [Year] = [] {
    didSet { tableView.reloadData() }
  }

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

extension YearsContainerViewController {
  override func viewDidLoad() {
    super.viewDidLoad()

    delegate = self
    dataSource = self
    title = L10n.Years.title
  }
}

extension YearsContainerViewController: YearsPresentable {
  func showYear(_ yearViewControllable: ViewControllable) {
    let yearViewController = yearViewControllable.uiviewController
    show(yearViewController, sender: nil)
  }
}

extension YearsContainerViewController: YearsViewControllable {
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

extension YearsContainerViewController: YearsViewControllerDataSource {
  func numberOfYears(in _: YearsViewController) -> Int {
    years.count
  }

  func yearsViewController(_: YearsViewController, yearAt index: Int) -> Year {
    years[index]
  }

  func yearsViewController(_: YearsViewController, downloadStateAt index: Int) -> YearDownloadState {
    listener?.downloadState(for: years[index]) ?? .available
  }
}

extension YearsContainerViewController: YearsViewControllerDelegate {
  func yearsViewController(_: YearsViewController, didSelectYearAt index: Int) {
    listener?.select(years[index])
  }
}
