import RIBs
import UIKit

typealias MoreDependency = HasAcknowledgementsService
  & HasInfoService
  & HasOpenService
  & HasTimeService
  & HasYearsBuilder
  & HasYearsService
  & HasVideosBuilder

protocol MoreBuildable: Buildable {
  func build() -> MoreRouting
}

final class MoreBuilder: Builder<MoreDependency>, MoreBuildable {
  func build() -> MoreRouting {
    let viewController = _MoreViewController()
    let interactor = MoreInteractor(presenter: viewController, dependency: dependency)
    let router = MoreRouter(interactor: interactor, viewController: viewController, videosBuilder: dependency.videosBuilder, yearsBuilder: dependency.yearsBuilder)
    viewController.listener = interactor
    interactor.router = router
    return router
  }
}

protocol MoreRouting: ViewableRouting {
  func routeToVideos()
  func routeToYears()
  func routeBackFromVideos()
  func routeBackFromYears()
}

final class MoreRouter: ViewableRouter<MoreInteractable, MoreViewControllable> {
  private var videosRouter: Routing?
  private var yearsRouter: Routing?

  private let videosBuilder: VideosBuildable
  private let yearsBuilder: YearsBuildable

  init(interactor: MoreInteractable, viewController: MoreViewControllable, videosBuilder: VideosBuildable, yearsBuilder: YearsBuildable) {
    self.videosBuilder = videosBuilder
    self.yearsBuilder = yearsBuilder
    super.init(interactor: interactor, viewController: viewController)
  }
}

extension MoreRouter: MoreRouting {
  func routeToVideos() {
    let videosRouter = videosBuilder.build(withListener: interactor)
    self.videosRouter = videosRouter
    attachChild(videosRouter)
    viewController.showVideos(videosRouter.viewControllable)
  }

  func routeBackFromVideos() {
    if let videosRouter = videosRouter {
      detachChild(videosRouter)
      self.videosRouter = nil
    }
  }

  func routeToYears() {
    let yearsRouter = yearsBuilder.build(withListener: interactor)
    self.yearsRouter = yearsRouter
    attachChild(yearsRouter)
    viewController.showYears(yearsRouter.viewControllable)
  }

  func routeBackFromYears() {
    if let yearsRouter = yearsRouter {
      detachChild(yearsRouter)
      self.yearsRouter = nil
    }
  }
}

protocol MoreInteractable: Interactable, VideosListener, YearsListener {}

final class MoreInteractor: PresentableInteractor<MorePresentable> {
  weak var router: MoreRouting?

  private var acknowledgements: [Acknowledgement] = []

  private let dependency: MoreDependency

  init(presenter: MorePresentable, dependency: MoreDependency) {
    self.dependency = dependency
    super.init(presenter: presenter)
  }
}

extension MoreInteractor: MoreInteractable {
  func videosDidDismiss() {
    router?.routeBackFromVideos()
  }

  func videosDidError(_: Error) {
    presenter.hideVideos()
    presenter.showError()
  }

  func yearsDidError(_: Error) {
    presenter.hideYears()
    presenter.showError()
  }
}

extension MoreInteractor: MorePresentableListener {
  func didSelect(_ item: MoreItem) {
    switch item {
    case .acknowledgements:
      do {
        presenter.showAcknowledgements(
          try dependency.acknowledgementsService.loadAcknowledgements()
        )
      } catch {
        presenter.showError()
      }
    case .code:
      if let url = URL.fosdemGithub {
        dependency.openService.open(url) { [weak self] _ in
          self?.presenter.deselectSelectedItem()
        }
      }
    case .history, .legal, .devrooms:
      if let info = item.info {
        dependency.infoService.loadAttributedText(for: info) { [weak self] result in
          DispatchQueue.main.async {
            switch result {
            case .failure:
              self?.presenter.showError()
            case let .success(attributedString):
              self?.presenter.showInfo(info, attributedString: attributedString)
            }
          }
        }
      }
    case .transportation:
      presenter.showTransportation()
    case .video:
      router?.routeToVideos()
    case .years:
      router?.routeToYears()
    #if DEBUG
    case .time:
      presenter.showDate(dependency.timeService.now)
    #endif
    }
  }

  func didSelect(_ item: TransportationItem) {
    switch item {
    case .appleMaps:
      dependency.openService.open(.ulbAppleMaps) { [weak self] _ in
        self?.presenter.deselectSelectedTransportationItem()
      }
    case .googleMaps:
      dependency.openService.open(.ulbGoogleMaps) { [weak self] _ in
        self?.presenter.deselectSelectedTransportationItem()
      }
    case .bus, .car, .taxi, .plane, .train, .shuttle:
      if let info = item.info {
        dependency.infoService.loadAttributedText(for: info) { [weak self] result in
          DispatchQueue.main.async {
            switch result {
            case .failure:
              self?.presenter.showError()
            case let .success(attributedString):
              self?.presenter.showTransportationInfo(info, attributedString: attributedString)
            }
          }
        }
      }
    }
  }

  func didSelect(_ acknowledgement: Acknowledgement) {
    open(acknowledgement.url) { [weak self] in
      self?.presenter.deselectSelectedAcknowledgment()
    }
  }

  func didDeselectVideos() {
    router?.routeBackFromVideos()
  }

  func didDeselectYears() {
    router?.routeBackFromYears()
  }

  private func open(_ url: URL, completion: @escaping () -> Void) {
    dependency.openService.open(url) { _ in
      completion()
    }
  }
}

#if DEBUG
extension MoreInteractor {
  func didSelectDate(_ date: Date) {
    dependency.timeService.now = date
  }
}
#endif

protocol MoreViewControllable: ViewControllable {
  func showVideos(_ videosViewControllable: ViewControllable)
  func showYears(_ yearsViewControllable: ViewControllable)
}

protocol MorePresentable: Presentable {
  func deselectSelectedAcknowledgment()
  func deselectSelectedItem()
  func deselectSelectedTransportationItem()
  func hideVideos()
  func hideYears()
  func showError()
  func showAcknowledgements(_ acknowledgements: [Acknowledgement])
  func showInfo(_ info: Info, attributedString: NSAttributedString)
  func showTransportation()
  func showTransportationInfo(_ info: Info, attributedString: NSAttributedString)
  #if DEBUG
  func showDate(_ date: Date)
  #endif
}

protocol MorePresentableListener: AnyObject {
  func didSelect(_ acknowledgement: Acknowledgement)
  func didSelect(_ item: MoreItem)
  func didSelect(_ item: TransportationItem)
  func didDeselectVideos()
  func didDeselectYears()
  #if DEBUG
  func didSelectDate(_ date: Date)
  #endif
}

final class _MoreViewController: UISplitViewController {
  weak var listener: MorePresentableListener?

  private(set) var acknowledgements: [Acknowledgement] = []

  private weak var acknowledgementsViewController: AcknowledgementsViewController?
  private weak var moreViewController: MoreViewController?
  private weak var transportationViewController: TransportationViewController?
  private weak var videosViewController: UIViewController?
  private weak var yearsViewController: UIViewController?
}

extension _MoreViewController {
  override func viewDidLoad() {
    super.viewDidLoad()

    let moreViewController = makeMoreViewController()
    let moreNavigationController = UINavigationController(rootViewController: moreViewController)
    moreNavigationController.navigationBar.prefersLargeTitles = true

    viewControllers = [moreNavigationController]
    if traitCollection.horizontalSizeClass == .regular {
      self.moreViewController(moreViewController, didSelect: .history)
    }
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
      if traitCollection.horizontalSizeClass == .regular, viewControllers.count < 2 {
        if let moreViewController = moreViewController {
          self.moreViewController(moreViewController, didSelect: .history)
        }
      }
    }
  }
}

extension _MoreViewController: MoreViewControllable {
  func showVideos(_ videosViewControllable: ViewControllable) {
    let videosViewController = videosViewControllable.uiviewController
    self.videosViewController = videosViewController
    showDetailViewController(videosViewController)
  }

  func showYears(_ yearsViewControllable: ViewControllable) {
    let yearsViewController = yearsViewControllable.uiviewController
    self.yearsViewController = yearsViewController
    showDetailViewController(yearsViewController)
  }
}

extension _MoreViewController: MorePresentable {
  func deselectSelectedItem() {
    moreViewController?.deselectSelectedRow(animated: true)
  }

  func deselectSelectedAcknowledgment() {
    acknowledgementsViewController?.deselectSelectedRow(animated: true)
  }

  func deselectSelectedTransportationItem() {
    transportationViewController?.deselectSelectedRow(animated: true)
  }

  func hideVideos() {
    if let moreViewController = moreViewController {
      self.moreViewController(moreViewController, didSelect: .history)
    }
  }

  func hideYears() {
    if let moreViewController = moreViewController {
      self.moreViewController(moreViewController, didSelect: .history)
    }
  }

  func showAcknowledgements(_ acknowledgements: [Acknowledgement]) {
    self.acknowledgements = acknowledgements

    let acknowledgementsViewController = makeAcknowledgementsViewController()
    let navigationController = UINavigationController(rootViewController: acknowledgementsViewController)
    showDetailViewController(navigationController)
  }

  func showError() {
    let errorViewController = UIAlertController.makeErrorController()
    moreViewController?.present(errorViewController, animated: true)
  }

  func showInfo(_ info: Info, attributedString: NSAttributedString) {
    let infoViewController = makeInfoViewController(with: info, attributedText: attributedString)
    let infoNavigationController = UINavigationController(rootViewController: infoViewController)
    showDetailViewController(infoNavigationController)
  }

  func showTransportation() {
    let transportationNavigationController = makeTransportationNavigationController()
    showDetailViewController(transportationNavigationController)
  }

  func showTransportationInfo(_ info: Info, attributedString: NSAttributedString) {
    let infoViewController = makeInfoViewController(with: info, attributedText: attributedString)
    transportationViewController?.show(infoViewController, sender: nil)
  }
}

#if DEBUG
extension _MoreViewController {
  func showDate(_ date: Date) {
    let dateViewController = makeDateViewController(for: date)
    moreViewController?.present(dateViewController, animated: true)
  }
}
#endif

extension _MoreViewController: MoreViewControllerDelegate {
  func moreViewController(_: MoreViewController, didSelect item: MoreItem) {
    listener?.didSelect(item)
  }
}

extension _MoreViewController: AcknowledgementsViewControllerDataSource, AcknowledgementsViewControllerDelegate {
  func acknowledgementsViewController(_: AcknowledgementsViewController, didSelect acknowledgement: Acknowledgement) {
    listener?.didSelect(acknowledgement)
  }
}

extension _MoreViewController: TransportationViewControllerDelegate {
  func transportationViewController(_: TransportationViewController, didSelect item: TransportationItem) {
    listener?.didSelect(item)
  }
}

#if DEBUG
extension _MoreViewController: UIPopoverPresentationControllerDelegate, DateViewControllerDelegate {
  func dateViewControllerDidChange(_ dateViewController: DateViewController) {
    listener?.didSelectDate(dateViewController.date)
  }
}
#endif

private extension _MoreViewController {
  var preferredDetailViewControllerStyle: UITableView.Style {
    if traitCollection.userInterfaceIdiom == .pad {
      return .fos_insetGrouped
    } else {
      return .grouped
    }
  }

  func showDetailViewController(_ detailViewController: UIViewController) {
    if detailViewController != videosViewController {
      listener?.didDeselectVideos()
    }
    if detailViewController != yearsViewController {
      listener?.didDeselectYears()
    }

    moreViewController?.showDetailViewController(detailViewController, sender: nil)
    UIAccessibility.post(notification: .screenChanged, argument: detailViewController.view)
  }
}

private extension _MoreViewController {
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
    self.acknowledgementsViewController = acknowledgementsViewController
    return acknowledgementsViewController
  }

  func makeInfoViewController(with info: Info, attributedText: NSAttributedString) -> TextViewController {
    let infoViewController = TextViewController()
    infoViewController.accessibilityIdentifier = info.accessibilityIdentifier
    infoViewController.attributedText = attributedText
    infoViewController.title = info.title
    return infoViewController
  }

  func makeTransportationNavigationController() -> UINavigationController {
    let transportationViewController = TransportationViewController(style: preferredDetailViewControllerStyle)
    transportationViewController.title = L10n.Transportation.title
    transportationViewController.delegate = self
    self.transportationViewController = transportationViewController

    let transportationNavigationController = UINavigationController(rootViewController: transportationViewController)
    transportationNavigationController.viewControllers = [transportationViewController]
    return transportationNavigationController
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
