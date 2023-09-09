import UIKit

final class MoreController: UISplitViewController {
  typealias Dependencies = HasNavigationService & HasAcknowledgementsService & HasYearsService & HasTimeService & HasOpenService

  private weak var moreViewController: MoreViewController?

  private(set) var acknowledgements: [Acknowledgement] = []

  #if DEBUG
  private var dependencies: Dependencies
  #else
  private let dependencies: Dependencies
  #endif

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func popToRootViewController() {
    if traitCollection.horizontalSizeClass == .compact {
      moreViewController?.navigationController?.popToRootViewController(animated: true)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let moreViewController = makeMoreViewController()
    let moreNavigationController = UINavigationController(rootViewController: moreViewController)
    moreNavigationController.navigationBar.prefersLargeTitles = true

    viewControllers = [moreNavigationController]
    if traitCollection.horizontalSizeClass == .regular {
      self.moreViewController(moreViewController, didSelectInfoItem: .history)
    }
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
      if traitCollection.horizontalSizeClass == .regular, viewControllers.count < 2 {
        if let moreViewController = moreViewController {
          self.moreViewController(moreViewController, didSelectInfoItem: .history)
        }
      }
    }
  }

  private func showDetailViewController(_ detailViewController: UIViewController) {
    moreViewController?.showDetailViewController(detailViewController, sender: nil)
    UIAccessibility.post(notification: .screenChanged, argument: detailViewController.view)
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
    case .overrideTime:
      let date = dependencies.timeService.now()
      let dateViewController = makeDateViewController(for: date)
      moreViewController.present(dateViewController, animated: true)
    case .generateDatabase:
      let databaseViewController = makeDatabaseViewController()
      moreViewController.present(databaseViewController, animated: true)
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
    let yearsViewController = makeYearsViewController(didError: { [weak self] _, _ in
      self?.moreViewControllerDidFailPresentation()
    })

    let navigationController = UINavigationController(rootViewController: yearsViewController)
    showDetailViewController(navigationController)
  }

  private func moreViewControllerDidSelectCode(_ moreViewController: MoreViewController) {
    if let url = URL.fosdemGithub {
      dependencies.openService.open(url) { [weak moreViewController] _ in
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
    popToRootViewController()
    moreViewController?.present(makeErrorViewController(), animated: true)
  }
}

extension MoreController: AcknowledgementsViewControllerDataSource, AcknowledgementsViewControllerDelegate {
  func acknowledgementsViewController(_ acknowledgementsViewController: AcknowledgementsViewController, didSelect acknowledgement: Acknowledgement) {
    dependencies.openService.open(acknowledgement.url) { [weak acknowledgementsViewController] _ in
      acknowledgementsViewController?.deselectSelectedRow(animated: true)
    }
  }
}

#if DEBUG
extension MoreController: UIPopoverPresentationControllerDelegate, DateViewControllerDelegate {
  func dateViewControllerDidChange(_ dateViewController: DateViewController) {
    dependencies.timeService.now = { dateViewController.date }
  }
}
#endif

private extension MoreController {
  private var preferredDetailViewControllerStyle: UITableView.Style {
    if traitCollection.userInterfaceIdiom == .pad {
      return .insetGrouped
    } else {
      return .grouped
    }
  }

  func makeMoreViewController() -> MoreViewController {
    let moreViewController = MoreViewController(style: .grouped)
    moreViewController.title = L10n.More.title
    moreViewController.delegate = self
    self.moreViewController = moreViewController
    return moreViewController
  }

  func makeAcknowledgementsViewController() -> AcknowledgementsViewController {
    let acknowledgementsViewController = AcknowledgementsViewController(style: preferredDetailViewControllerStyle)
    acknowledgementsViewController.title = L10n.Acknowledgements.title
    acknowledgementsViewController.dataSource = self
    acknowledgementsViewController.delegate = self
    return acknowledgementsViewController
  }

  private func makeYearsViewController(didError: @escaping NavigationService.ErrorHandler) -> UIViewController {
    dependencies.navigationService.makeYearsViewController(preferredDetailViewControllerStyle, didError)
  }

  private func makeTransportationViewController() -> UIViewController {
    dependencies.navigationService.makeTransportationViewController()
  }

  private func makeVideosViewController(didError: @escaping NavigationService.ErrorHandler) -> UIViewController {
    dependencies.navigationService.makeVideosViewController(didError)
  }

  private func makeInfoViewController(withTitle title: String, info: Info, didError: @escaping NavigationService.ErrorHandler) -> UIViewController {
    dependencies.navigationService.makeInfoViewController(title, info, didError)
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

  private func makeDatabaseViewController() -> UIAlertController {
    let title = "Generate database", message = "Specify the year you want to generate a database for"
    let databaseViewController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    databaseViewController.addAction(.init(title: "Cancel", style: .cancel))
    databaseViewController.addAction(.init(title: "Generate", style: .default) { _ in
      GenerateDatabaseService().generate { dump($0) }
    })
    return databaseViewController
  }
  #endif
}
