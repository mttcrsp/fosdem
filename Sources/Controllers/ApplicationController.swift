import UIKit

final class ApplicationController: NSObject {
  typealias Dependencies = HasNavigationService & HasLaunchService & HasTimeService & HasUpdateService & HasScheduleService & HasYearsService

  private weak var applicationViewController: ApplicationViewController?
  private weak var tabsController: UITabBarController?

  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
    super.init()

    dependencies.updateService.delegate = self
    dependencies.updateService.detectUpdates()
    dependencies.scheduleService?.startUpdating()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private var previouslySelectedViewController: String? {
    get { UserDefaults.standard.selectedViewController }
    set { UserDefaults.standard.selectedViewController = newValue }
  }

  func applicationDidBecomeActive() {
    dependencies.timeService.startMonitoring()
    dependencies.scheduleService?.startUpdating()
  }

  func applicationWillResignActive() {
    dependencies.timeService.stopMonitoring()
  }

  private func didTapUpdate() {
    if let url = URL.fosdemAppStore {
      UIApplication.shared.open(url)
    }
  }
}

extension ApplicationController: ApplicationViewControllerDelegate {
  func applicationViewControllerDidSelectPrev(_: ApplicationViewController) {
    if let tabsController = tabsController {
      let count = tabsController.children.count
      let index = tabsController.selectedIndex
      tabsController.selectedIndex = ((index - 1) + count) % count
    }
  }

  func applicationViewControllerDidSelectNext(_: ApplicationViewController) {
    if let tabsController = tabsController {
      let count = tabsController.children.count
      let index = tabsController.selectedIndex
      tabsController.selectedIndex = ((index + 1) + count) % count
    }
  }
}

extension ApplicationController {
  func makeApplicationViewController() -> ApplicationViewController {
    let applicationViewController: ApplicationViewController
    if UIDevice.current.userInterfaceIdiom == .phone, dependencies.launchService.didLaunchAfterInstall {
      applicationViewController = ApplicationViewController(topViewController: makeWelcomeViewController(), bottomViewController: makeTabsController())
    } else {
      applicationViewController = ApplicationViewController(topViewController: makeTabsController())
    }

    self.applicationViewController = applicationViewController
    return applicationViewController
  }

  private func makeTabsController() -> UITabBarController {
    let tabsController = UITabBarController()
    tabsController.delegate = self

    var viewControllers: [UIViewController] = []
    viewControllers.append(makeSearchController())
    viewControllers.append(makeAgendaController())
    viewControllers.append(makeMapController())
    viewControllers.append(makeMoreController())
    tabsController.setViewControllers(viewControllers, animated: false)

    for (index, viewController) in viewControllers.enumerated() where String(describing: type(of: viewController)) == previouslySelectedViewController {
      tabsController.selectedIndex = index
    }

    self.tabsController = tabsController
    return tabsController
  }

  private func makeSearchController() -> UIViewController {
    dependencies.navigationService.makeSearchViewController()
  }

  private func makeAgendaController() -> UIViewController {
    dependencies.navigationService.makeAgendaViewController(didError: { [weak self] viewController, error in
      self?.agendaController(viewController, didError: error)
    })
  }

  private func makeMapController() -> UIViewController {
    dependencies.navigationService.makeMapViewController(didError: { [weak self] viewController, error in
      self?.mapController(viewController, didError: error)
    })
  }

  private func makeMoreController() -> UIViewController {
    dependencies.navigationService.makeMoreViewController()
  }

  private func makeWelcomeViewController() -> WelcomeViewController {
    let welcomeViewController = WelcomeViewController(year: type(of: dependencies.yearsService).current)
    welcomeViewController.showsContinue = true
    welcomeViewController.delegate = self
    return welcomeViewController
  }

  private func makeUpdateViewController() -> UIAlertController {
    UIAlertController.makeConfirmController(with: .update) { [weak self] in
      self?.didTapUpdate()
    }
  }
}

extension ApplicationController: UITabBarControllerDelegate {
  func tabBarController(_: UITabBarController, didSelect viewController: UIViewController) {
    previouslySelectedViewController = String(describing: type(of: viewController))
  }
}

extension ApplicationController {
  func agendaController(_ agendaController: UIViewController, didError _: Error) {
    let errorViewController = ErrorViewController()
    agendaController.addChild(errorViewController)
    agendaController.view.addSubview(errorViewController.view)
    errorViewController.didMove(toParent: agendaController)
  }
}

extension ApplicationController {
  func mapController(_ mapController: UIViewController, didError _: Error) {
    let errorViewController = ErrorViewController()
    mapController.addChild(errorViewController)
    mapController.view.addSubview(errorViewController.view)
    errorViewController.didMove(toParent: mapController)
  }
}

extension ApplicationController: UpdateServiceDelegate {
  func updateServiceDidDetectUpdate(_: UpdateService) {
    DispatchQueue.main.async { [weak self] in
      if let self = self, let applicationViewController = self.applicationViewController {
        let updateViewController = self.makeUpdateViewController()
        applicationViewController.present(updateViewController, animated: true)
      }
    }
  }
}

extension ApplicationController: WelcomeViewControllerDelegate {
  func welcomeViewControllerDidTapContinue(_: WelcomeViewController) {
    applicationViewController?.showBottomViewController()
  }
}

private extension UserDefaults {
  var selectedViewController: String? {
    get { string(forKey: .selectedViewControllerKey) }
    set { set(newValue, forKey: .selectedViewControllerKey) }
  }
}

private extension String {
  static var selectedViewControllerKey: String { #function }
}

private extension UIAlertController.ConfirmConfiguration {
  static var update: UIAlertController.ConfirmConfiguration {
    UIAlertController.ConfirmConfiguration(
      title: L10n.Update.title,
      message: L10n.Update.message,
      confirm: L10n.Update.confirm,
      dismiss: L10n.Update.dismiss
    )
  }
}
