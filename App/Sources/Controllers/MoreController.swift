import UIKit

final class MoreController: UISplitViewController {
  typealias Dependencies = HasAcknowledgementsService & HasNavigationService & HasOpenService & HasTimeService & HasYearsService

  private weak var moreViewController: MoreViewController?

  private(set) var acknowledgements: [Acknowledgement] = []

  private let dependencies: Dependencies

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

    let moreViewController = MoreViewController(style: .grouped)
    moreViewController.title = L10n.More.title
    moreViewController.delegate = self
    self.moreViewController = moreViewController

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
        if let moreViewController {
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
      if let url = URL.fosdemGithub {
        dependencies.openService.open(url) { [weak moreViewController] _ in
          moreViewController?.deselectSelectedRow(animated: true)
        }
      }

    case .years:
      let yearsViewController = dependencies.navigationService.makeYearsViewController(withStyle: preferredDetailViewControllerStyle)
      yearsViewController.didError = { [weak self] _, _ in
        self?.moreViewControllerDidFailPresentation()
      }

      let navigationController = UINavigationController(rootViewController: yearsViewController)
      showDetailViewController(navigationController)

    case .video:
      let videosViewController = dependencies.navigationService.makeVideosViewController()
      videosViewController.didError = { [weak self] _, _ in
        self?.moreViewControllerDidFailPresentation()
      }

      let navigationController = UINavigationController(rootViewController: videosViewController)
      moreViewController.showDetailViewController(navigationController, sender: nil)

    case .transportation:
      let transportationViewController = dependencies.navigationService.makeTransportationViewController()
      showDetailViewController(transportationViewController)

    case .acknowledgements:
      do {
        acknowledgements = try dependencies.acknowledgementsService.loadAcknowledgements()

        let acknowledgementsViewController = AcknowledgementsViewController(style: preferredDetailViewControllerStyle)
        acknowledgementsViewController.title = L10n.Acknowledgements.title
        acknowledgementsViewController.dataSource = self
        acknowledgementsViewController.delegate = self

        let navigationController = UINavigationController(rootViewController: acknowledgementsViewController)
        showDetailViewController(navigationController)
      } catch {
        let errorViewController = UIAlertController.makeErrorController()
        moreViewController.present(errorViewController, animated: true)
      }

    case .history, .legal, .devrooms:
      self.moreViewController(moreViewController, didSelectInfoItem: item)

    #if DEBUG
    case .overrideTime:
      let dateViewController = DateViewController()
      dateViewController.date = dependencies.timeService.now
      dateViewController.delegate = self
      moreViewController.present(dateViewController, animated: true)

    case .generateDatabase:
      #if targetEnvironment(simulator)
      let title = "Generate database", message = "Specify the year you want to generate a database for. Check the Xcode console for the path to the generated database file."
      let databaseViewController = UIAlertController(title: title, message: message, preferredStyle: .alert)
      databaseViewController.addTextField { textField in
        textField.keyboardType = .numberPad
        textField.placeholder = "YYYY"
      }
      databaseViewController.addAction(.init(title: "Cancel", style: .cancel))
      databaseViewController.addAction(.init(title: "Generate", style: .default) { [weak databaseViewController] _ in
        guard let text = databaseViewController?.textFields?.first?.text, let year = Year(text) else { return }
        GenerateDatabaseService().generate(forYear: year) { dump($0) }
      })
      moreViewController.present(databaseViewController, animated: true)
      #else
      let title = "Ooops", message = "Database files can only be generated while running on a Simulator"
      let errorViewController = UIAlertController(title: title, message: message, preferredStyle: .alert)
      errorViewController.addAction(.init(title: "Ok", style: .default))
      moreViewController.present(errorViewController, animated: true)
      #endif
    #endif
    }
  }

  private func moreViewController(_ moreViewController: MoreViewController, didSelectInfoItem item: MoreItem) {
    guard let info = item.info else {
      return assertionFailure("Failed to determine info model for more item '\(item)'")
    }

    let infoViewController = dependencies.navigationService.makeInfoViewController(for: info)
    infoViewController.accessibilityIdentifier = info.accessibilityIdentifier
    infoViewController.title = item.title
    infoViewController.load { [weak self] error in
      guard let self else { return }

      if error != nil {
        let errorViewController = UIAlertController.makeErrorController()
        moreViewController.present(errorViewController, animated: true)
      } else {
        let navigationController = UINavigationController(rootViewController: infoViewController)
        showDetailViewController(navigationController)
      }
    }
  }

  private func moreViewControllerDidFailPresentation() {
    popToRootViewController()

    let errorViewController = UIAlertController.makeErrorController()
    moreViewController?.present(errorViewController, animated: true)
  }

  private func showDetailViewController(_ detailViewController: UIViewController) {
    moreViewController?.showDetailViewController(detailViewController, sender: nil)
    UIAccessibility.post(notification: .screenChanged, argument: detailViewController.view)
  }

  private var preferredDetailViewControllerStyle: UITableView.Style {
    traitCollection.userInterfaceIdiom == .pad ? .insetGrouped : .grouped
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
    dependencies.timeService.now = dateViewController.date
  }
}
#endif
