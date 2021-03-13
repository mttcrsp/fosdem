import L10n
import UIKit

final class MoreController: UISplitViewController {
  private weak var moreViewController: MoreViewController?

  private(set) var acknowledgements: [Acknowledgement] = []
  private var years: [String] = []

  private let services: Services

  init(services: Services) {
    self.services = services
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
      showDetailInfoViewController(for: .history)
    }
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
      if traitCollection.horizontalSizeClass == .regular, viewControllers.count < 2 {
        showDetailInfoViewController(for: .history)
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
      showDetailInfoViewController(for: item)
    #if DEBUG
    case .time:
      let date = services.debugService.now
      let dateViewController = makeDateViewController(for: date)
      moreViewController.present(dateViewController, animated: true)
    #endif
    }
  }

  private func moreViewControllerDidSelectAcknowledgements(_ moreViewController: MoreViewController) {
    do {
      acknowledgements = try services.acknowledgementsService.loadAcknowledgements()
      let acknowledgementsViewController = makeAcknowledgementsViewController()
      let navigationController = UINavigationController(rootViewController: acknowledgementsViewController)
      showDetailViewController(navigationController)
    } catch {
      let errorViewController = makeErrorViewController()
      moreViewController.present(errorViewController, animated: true)
    }
  }

  private func moreViewControllerDidSelectVideo(_ moreViewController: MoreViewController) {
    let videosViewController = makeVideosViewController()
    let navigationController = UINavigationController(rootViewController: videosViewController)
    moreViewController.showDetailViewController(navigationController, sender: nil)
  }

  private func moreViewControllerDidSelectYears(_: MoreViewController) {
    services.yearsService.loadYears { years in
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
    let navigationController = UINavigationController(rootViewController: transportationViewController)
    showDetailViewController(navigationController)
  }

  private func showDetailInfoViewController(for item: MoreItem) {
    guard let info = item.info else {
      return assertionFailure("Failed to determine info model for more item '\(item)'")
    }

    makeInfoViewController(withTitle: item.title, for: info) { [weak self, weak moreViewController] infoViewController in
      guard let self = self else { return }

      if let infoViewController = infoViewController {
        let navigationController = UINavigationController(rootViewController: infoViewController)
        self.showDetailViewController(navigationController)
      } else {
        let errorViewController = self.makeErrorViewController()
        moreViewController?.present(errorViewController, animated: true)
      }
    }
  }
}

extension MoreController: TransportationViewControllerDelegate {
  func transportationViewController(_ transportationViewController: TransportationViewController, didSelect item: TransportationViewController.Item) {
    switch item {
    case .appleMaps:
      UIApplication.shared.open(.ulbAppleMaps) { [weak transportationViewController] _ in
        transportationViewController?.deselectSelectedRow(animated: true)
      }
    case .googleMaps:
      UIApplication.shared.open(.ulbGoogleMaps) { [weak transportationViewController] _ in
        transportationViewController?.deselectSelectedRow(animated: true)
      }
    case .bus, .car, .taxi, .plane, .train, .shuttle:
      guard let info = item.info else {
        return assertionFailure("Failed to determine info model for transportation item '\(item)'")
      }

      makeInfoViewController(withTitle: item.title, for: info) { [weak self, weak transportationViewController] infoViewController in
        guard let self = self else { return }

        if let infoViewController = infoViewController {
          transportationViewController?.show(infoViewController, sender: nil)
        } else {
          let errorViewController = self.makeErrorViewController()
          transportationViewController?.present(errorViewController, animated: true)
        }
      }
    }
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
    services.yearsService.loadURL(forYear: year) { [weak self, weak yearsViewController] url in
      guard let self = self, let yearsViewController = yearsViewController else { return }

      guard let url = url else {
        return self.presentYearErrorViewController(from: yearsViewController)
      }

      do {
        let persistenceService = try PersistenceService(path: url.path, migrations: .allMigrations)
        self.showYearViewController(forYear: year, with: persistenceService, from: yearsViewController)
      } catch {
        assertionFailure(error.localizedDescription)
        self.presentYearErrorViewController(from: yearsViewController)
      }
    }
  }

  private func presentYearErrorViewController(from yearsViewController: YearsViewController) {
    DispatchQueue.main.async { [weak self, weak yearsViewController] in
      guard let self = self else { return }

      let errorViewController = self.makeErrorViewController()
      yearsViewController?.present(errorViewController, animated: true)
    }
  }

  private func showYearViewController(forYear year: String, with persistenceService: PersistenceService, from yearsViewController: YearsViewController) {
    DispatchQueue.main.async { [weak self, weak yearsViewController] in
      guard let self = self else { return }

      let yearViewController = self.makeYearViewController(forYear: year, with: persistenceService)
      yearsViewController?.show(yearViewController, sender: nil)
    }
  }
}

extension MoreController: YearControllerDelegate {
  func yearControllerDidError(_ yearController: YearController) {
    let navigationController = yearController.navigationController
    navigationController?.popViewController(animated: true)

    let errorViewController = makeErrorViewController()
    present(errorViewController, animated: true)
  }
}

extension MoreController: AcknowledgementsViewControllerDataSource, AcknowledgementsViewControllerDelegate {
  func acknowledgementsViewController(_ acknowledgementsViewController: AcknowledgementsViewController, didSelect acknowledgement: Acknowledgement) {
    UIApplication.shared.open(acknowledgement.url) { [weak acknowledgementsViewController] _ in
      acknowledgementsViewController?.deselectSelectedRow(animated: true)
    }
  }
}

extension MoreController: VideosControllerDelegate {
  func videosController(_ videosController: VideosController, didError _: Error) {
    let errorViewController = makeErrorViewController { [weak self] in
      self?.popToRootViewController()
    }
    videosController.present(errorViewController, animated: true)
  }
}

#if DEBUG
extension MoreController: UIPopoverPresentationControllerDelegate, DateViewControllerDelegate {
  func dateViewControllerDidChange(_ dateViewController: DateViewController) {
    let date = dateViewController.date
    services.debugService.override(date)
  }
}
#endif

private extension MoreController {
  private var preferredDetailViewControllerStyle: UITableView.Style {
    if traitCollection.userInterfaceIdiom == .pad {
      return .fos_insetGrouped
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

  private func makeInfoViewController(withTitle title: String, for info: Info, completion: @escaping (TextViewController?) -> Void) {
    services.infoService.loadAttributedText(for: info) { attributedText in
      DispatchQueue.main.async {
        if let attributedText = attributedText {
          let textViewController = TextViewController()
          textViewController.accessibilityIdentifier = info.accessibilityIdentifier
          textViewController.attributedText = attributedText
          textViewController.title = title
          completion(textViewController)
        } else {
          completion(nil)
        }
      }
    }
  }

  func makeYearsViewController() -> YearsViewController {
    let yearsViewController = YearsViewController(style: preferredDetailViewControllerStyle)
    yearsViewController.title = L10n.Years.title
    yearsViewController.dataSource = self
    yearsViewController.delegate = self
    return yearsViewController
  }

  private func makeTransportationViewController() -> TransportationViewController {
    let transportationViewController = TransportationViewController(style: preferredDetailViewControllerStyle)
    transportationViewController.title = L10n.Transportation.title
    transportationViewController.delegate = self
    return transportationViewController
  }

  func makeYearViewController(forYear year: String, with persistenceService: PersistenceService) -> YearController {
    let yearController = YearController(year: year, yearPersistenceService: persistenceService, services: services)
    yearController.navigationItem.largeTitleDisplayMode = .never
    yearController.yearDelegate = self
    yearController.title = year
    return yearController
  }

  func makeAcknowledgementsViewController() -> AcknowledgementsViewController {
    let acknowledgementsViewController = AcknowledgementsViewController(style: preferredDetailViewControllerStyle)
    acknowledgementsViewController.title = L10n.Acknowledgements.title
    acknowledgementsViewController.dataSource = self
    acknowledgementsViewController.delegate = self
    return acknowledgementsViewController
  }

  private func makeVideosViewController() -> VideosController {
    let videosViewController = VideosController(services: services)
    videosViewController.videoDelegate = self
    return videosViewController
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

private extension URL {
  static var ulbAppleMaps: URL {
    URL(string: "https://maps.apple.com/?address=Avenue%20Franklin%20Roosevelt%2050,%201050%20Brussels,%20Belgium&auid=2450730505287536200&ll=50.812050,4.382236&lsp=9902&q=Universit%C3%A9%20Libre%20de%20Bruxelles&_ext=ChgKBAgEEFcKBAgFEAMKBAgGEBkKBAgKEAESJCkjtQWwbFxJQDFgm0ZDufUQQDkZviUmcHNJQEGgZLl8GBkSQA%3D%3D")!
  }

  static var ulbGoogleMaps: URL {
    URL(string: "https://www.google.com/maps/place/Universit%C3%A9+Libre+de+Bruxelles/@50.8132068,4.3800335,17z/data=!3m1!4b1!4m5!3m4!1s0x47c3c4485d19ce43:0xe8eb9253c07c6691!8m2!3d50.8132068!4d4.3822222")!
  }
}
