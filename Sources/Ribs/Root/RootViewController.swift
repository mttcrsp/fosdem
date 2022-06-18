import RIBs
import UIKit

protocol RootPresentableListener: AnyObject {
  func openAppStore()
}

class RootViewController: UIViewController, UITabBarControllerDelegate {
  weak var listener: RootPresentableListener?

  private weak var tabsController: UITabBarController?

  override func viewDidLoad() {
    super.viewDidLoad()

    let tabsController = UITabBarController()
    tabsController.delegate = self
    self.tabsController = tabsController

    add(tabsController)

    view.backgroundColor = .fos_systemGroupedBackground
  }

  private var agendaViewController: UIViewController? {
    didSet { didChangeViewControllers() }
  }

  private var mapViewController: UIViewController? {
    didSet { didChangeViewControllers() }
  }

  private var moreViewController: UIViewController? {
    didSet { didChangeViewControllers() }
  }

  private var scheduleViewController: UIViewController? {
    didSet { didChangeViewControllers() }
  }

  private func add(_ viewController: UIViewController) {
    addChild(viewController)
    view.addSubview(viewController.view)
    viewController.view.translatesAutoresizingMaskIntoConstraints = false
    viewController.didMove(toParent: self)

    NSLayoutConstraint.activate([
      viewController.view.topAnchor.constraint(equalTo: view.topAnchor),
      viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
  }

  private func didChangeViewControllers() {
    let viewControllers = [scheduleViewController, agendaViewController, mapViewController, moreViewController]
    tabsController?.viewControllers = viewControllers.compactMap { $0 }
  }
}

extension RootViewController: RootPresentable {
  func showError() {
    let errorViewController = UIAlertController.makeErrorController()
    present(errorViewController, animated: true)
  }

  func showFailure() {
    let errorViewController = ErrorViewController()
    errorViewController.delegate = self
    errorViewController.showsAppStoreButton = true
    add(errorViewController)
  }

  func showWelcome(for year: Year) {
    let welcomeViewController = WelcomeViewController()
    welcomeViewController.year = year
    welcomeViewController.delegate = self
    welcomeViewController.showsContinue = true
    add(welcomeViewController)
  }
}

extension RootViewController: RootViewControllable {
  func addAgenda(_ agendaViewControllable: ViewControllable) {
    agendaViewController = agendaViewControllable.uiviewController
    agendaViewController?.title = L10n.Agenda.title
    agendaViewController?.tabBarItem.accessibilityIdentifier = "agenda"
    agendaViewController?.tabBarItem.image = .fos_systemImage(withName: "calendar")
  }

  func addMap(_ mapViewControllable: ViewControllable) {
    mapViewController = mapViewControllable.uiviewController
    mapViewController?.title = L10n.Map.title
    mapViewController?.tabBarItem.accessibilityIdentifier = "map"
    mapViewController?.tabBarItem.image = .fos_systemImage(withName: "map")
  }

  func addMore(_ mapViewControllable: ViewControllable) {
    moreViewController = mapViewControllable.uiviewController
    moreViewController?.title = L10n.More.title
    moreViewController?.tabBarItem.accessibilityIdentifier = "more"
    moreViewController?.tabBarItem.image = .fos_systemImage(withName: "ellipsis.circle")
  }

  func addSchedule(_ scheduleViewControllable: ViewControllable) {
    scheduleViewController = scheduleViewControllable.uiviewController
    scheduleViewController?.title = L10n.Search.title
    scheduleViewController?.tabBarItem.accessibilityIdentifier = "search"
    scheduleViewController?.tabBarItem.image = .fos_systemImage(withName: "magnifyingglass")
  }

  func removeAgenda() {
    agendaViewController = nil
  }

  func removeMap() {
    mapViewController = nil
  }
}

extension RootViewController: ErrorViewControllerDelegate {
  func errorViewControllerDidTapAppStore(_: ErrorViewController) {
    listener?.openAppStore()
  }
}

extension RootViewController: WelcomeViewControllerDelegate {
  func welcomeViewControllerDidTapContinue(_ welcomeViewController: WelcomeViewController) {
    tabsController?.view.transform = .init(translationX: 0, y: 60)
    welcomeViewController.willMove(toParent: nil)
    UIView.animate(withDuration: 0.2) {
      self.tabsController?.view.transform = .identity
      welcomeViewController.view.alpha = 0
    } completion: { _ in
      welcomeViewController.view.removeFromSuperview()
      welcomeViewController.removeFromParent()
    }
  }
}
