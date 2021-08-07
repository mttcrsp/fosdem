import UIKit

final class MoreController: NSObject {
  typealias Dependencies = HasNavigationService & HasAcknowledgementsService & HasYearsService & HasTimeService

  private weak var moreSplitViewController: UISplitViewController?
  private weak var moreViewController: MoreViewController?

  private(set) var acknowledgements: [Acknowledgement] = []
  private var years: [String] = []

  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func showDetailViewController(_ detailViewController: UIViewController) {
    moreViewController?.showDetailViewController(detailViewController, sender: nil)
    UIAccessibility.post(notification: .screenChanged, argument: detailViewController.view)
  }
}

extension MoreController: MoreSplitViewControllerDelegate {
  func splitViewController(_ splitViewController: MoreSplitViewController, didChangeTraitCollectionFrom previousTraitCollection: UITraitCollection?) {
    if splitViewController.traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
      if splitViewController.traitCollection.horizontalSizeClass == .regular, splitViewController.viewControllers.count < 2 {
        if let moreViewController = moreViewController {
          self.moreViewController(moreViewController, didSelectInfoItem: .history)
        }
      }
    }
  }
}

extension MoreController: MoreViewControllerDelegate {
  func moreViewController(_ moreViewController: MoreViewController, didSelect item: MoreItem) {
    switch item {
    case .code:
      moreViewControllerDidSelectCode(moreViewController)
    case .years:
      moreViewControllerDidSelectYears(moreViewController)
    case .video:
      moreViewControllerDidSelectVideo(moreViewController)
    case .transportation:
      moreViewControllerDidSelectTransportation(moreViewController)
    case .acknowledgements:
      moreViewControllerDidSelectAcknowledgements(moreViewController)
    case .history, .legal, .devrooms:
      self.moreViewController(moreViewController, didSelectInfoItem: item)
    #if DEBUG
    case .time:
      let date = dependencies.timeService.now
      let dateViewController = makeDateViewController(for: date)
      moreViewController.present(dateViewController, animated: true)
    #endif
    }
  }

  private func moreViewControllerDidSelectAcknowledgements(_ moreViewController: MoreViewController) {
    do {
      acknowledgements = try dependencies.acknowledgementsService.loadAcknowledgements()
      let acknowledgementsViewController = makeAcknowledgementsViewController()
      let navigationController = UINavigationController(rootViewController: acknowledgementsViewController)
      showDetailViewController(navigationController)
    } catch {
      let errorViewController = makeErrorViewController()
      moreViewController.present(errorViewController, animated: true)
    }
  }

  private func moreViewControllerDidSelectVideo(_ moreViewController: MoreViewController) {
    let videosViewController = makeVideosViewController(didError: { [weak self] _, _ in
      self?.moreViewControllerDidFailPresentation()
    })

    let navigationController = UINavigationController(rootViewController: videosViewController)
    moreViewController.showDetailViewController(navigationController, sender: nil)
  }

  private func moreViewControllerDidSelectYears(_: MoreViewController) {
    dependencies.yearsService.loadYears { years in
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }

        self.years = years
        let yearsViewController = self.makeYearsViewController()
        let navigationController = UINavigationController(rootViewController: yearsViewController)
        self.showDetailViewController(navigationController)
      }
    }
  }

  private func moreViewControllerDidSelectCode(_ moreViewController: MoreViewController) {
    if let url = URL.fosdemGithub {
      UIApplication.shared.open(url) { [weak moreViewController] _ in
        moreViewController?.deselectSelectedRow(animated: true)
      }
    }
  }

  private func moreViewControllerDidSelectTransportation(_: MoreViewController) {
    let transportationViewController = makeTransportationViewController()
    showDetailViewController(transportationViewController)
  }

  private func moreViewController(_: MoreViewController, didSelectInfoItem item: MoreItem) {
    guard let info = item.info else {
      return assertionFailure("Failed to determine info model for more item '\(item)'")
    }

    let infoViewController = makeInfoViewController(withTitle: item.title, info: info, didError: { [weak self] _, _ in
      self?.moreViewControllerDidFailPresentation()
    })

    let navigationController = UINavigationController(rootViewController: infoViewController)
    showDetailViewController(navigationController)
  }

  private func moreViewControllerDidFailPresentation() {
    if moreSplitViewController?.traitCollection.horizontalSizeClass == .compact {
      moreViewController?.navigationController?.popToRootViewController(animated: true)
    }
    moreViewController?.present(makeErrorViewController(), animated: true)
  }
}

extension MoreController: YearsViewControllerDataSource, YearsViewControllerDelegate {
  func numberOfYears(in _: YearsViewController) -> Int {
    years.count
  }

  func yearsViewController(_: YearsViewController, yearAt index: Int) -> String {
    years[index]
  }

  func yearsViewController(_ yearsViewController: YearsViewController, didSelect year: String) {
    dependencies.yearsService.loadURL(forYear: year) { [weak self, weak yearsViewController] url in
      guard let self = self, let yearsViewController = yearsViewController else { return }

      guard let url = url, let persistenceService = try? PersistenceService(path: url.path, migrations: .allMigrations) else {
        return DispatchQueue.main.async { [weak self] in
          self?.presentYearErrorViewController(from: yearsViewController)
        }
      }

      DispatchQueue.main.async { [weak self] in
        self?.showYearViewController(forYear: year, with: persistenceService, from: yearsViewController)
      }
    }
  }

  private func presentYearErrorViewController(from yearsViewController: YearsViewController) {
    let errorViewController = makeErrorViewController()
    yearsViewController.present(errorViewController, animated: true)
  }

  private func showYearViewController(forYear year: String, with persistenceService: PersistenceService, from yearsViewController: YearsViewController) {
    let yearViewController = makeYearViewController(forYear: year, with: persistenceService, didError: { [weak self] _, _ in
      self?.moreViewControllerDidFailPresentation()
    })
    yearsViewController.show(yearViewController, sender: nil)
  }
}

extension MoreController: AcknowledgementsViewControllerDataSource, AcknowledgementsViewControllerDelegate {
  func acknowledgementsViewController(_ acknowledgementsViewController: AcknowledgementsViewController, didSelect acknowledgement: Acknowledgement) {
    UIApplication.shared.open(acknowledgement.url) { [weak acknowledgementsViewController] _ in
      acknowledgementsViewController?.deselectSelectedRow(animated: true)
    }
  }
}

#if DEBUG
extension MoreController: UIPopoverPresentationControllerDelegate, DateViewControllerDelegate {
  func dateViewControllerDidChange(_ dateViewController: DateViewController) {
    dependencies.timeService.now = dateViewController.date
  }
}
#endif

extension MoreController {
  private var preferredDetailViewControllerStyle: UITableView.Style {
    if UIDevice.current.userInterfaceIdiom == .phone {
      return .grouped
    } else {
      return .fos_insetGrouped
    }
  }

  func makeMoreSplitViewController() -> UISplitViewController {
    let moreViewController = makeMoreViewController()
    let moreNavigationController = UINavigationController(rootViewController: moreViewController)
    moreNavigationController.navigationBar.prefersLargeTitles = true

    let moreSplitViewController = MoreSplitViewController()
    self.moreSplitViewController = moreSplitViewController
    moreSplitViewController.moreDelegate = self
    moreSplitViewController.viewControllers = [moreNavigationController]

    if moreSplitViewController.traitCollection.horizontalSizeClass == .regular {
      self.moreViewController(moreViewController, didSelectInfoItem: .history)
    }

    return moreSplitViewController
  }

  private func makeMoreViewController() -> MoreViewController {
    let moreViewController = MoreViewController(style: .grouped)
    moreViewController.title = L10n.More.title
    moreViewController.delegate = self
    self.moreViewController = moreViewController
    return moreViewController
  }

  private func makeYearsViewController() -> YearsViewController {
    let yearsViewController = YearsViewController(style: preferredDetailViewControllerStyle)
    yearsViewController.title = L10n.Years.title
    yearsViewController.dataSource = self
    yearsViewController.delegate = self
    return yearsViewController
  }

  private func makeAcknowledgementsViewController() -> AcknowledgementsViewController {
    let acknowledgementsViewController = AcknowledgementsViewController(style: preferredDetailViewControllerStyle)
    acknowledgementsViewController.title = L10n.Acknowledgements.title
    acknowledgementsViewController.dataSource = self
    acknowledgementsViewController.delegate = self
    return acknowledgementsViewController
  }

  private func makeTransportationViewController() -> UIViewController {
    dependencies.navigationService.makeTransportationViewController()
  }

  private func makeVideosViewController(didError: @escaping NavigationService.ErrorHandler) -> UIViewController {
    dependencies.navigationService.makeVideosViewController(didError: didError)
  }

  private func makeInfoViewController(withTitle title: String, info: Info, didError: @escaping NavigationService.ErrorHandler) -> UIViewController {
    dependencies.navigationService.makeInfoViewController(withTitle: title, info: info, didError: didError)
  }

  private func makeYearViewController(forYear year: String, with persistenceService: PersistenceService, didError: @escaping NavigationService.ErrorHandler) -> UIViewController {
    dependencies.navigationService.makeYearsViewController(forYear: year, with: persistenceService, didError: didError)
  }

  private func makeErrorViewController(withHandler handler: (() -> Void)? = nil) -> UIAlertController {
    UIAlertController.makeErrorController(withHandler: handler)
  }

  #if DEBUG
  private func makeDateViewController(for date: Date) -> DateViewController {
    let timeViewController = DateViewController()
    timeViewController.delegate = self
    timeViewController.date = date
    return timeViewController
  }
  #endif
}
