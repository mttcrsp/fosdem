import UIKit

final class ApplicationController: UIViewController {
  typealias Dependencies = HasNavigationService & HasLaunchService & HasLiveService & HasUpdateService & HasScheduleService & HasYearsService

  private weak var tabsController: UITabBarController?

  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private var previouslySelectedViewController: String? {
    get { UserDefaults.standard.selectedViewController }
    set { UserDefaults.standard.selectedViewController = newValue }
  }

  override var canBecomeFirstResponder: Bool {
    true
  }

  override var keyCommands: [UIKeyCommand]? {
    let prevModifierFlags: UIKeyModifierFlags = [.alternate, .shift]
    let nextModifierFlags: UIKeyModifierFlags = [.alternate]
    let prevAction = #selector(didSelectPrevTab)
    let nextAction = #selector(didSelectNextTab)
    let prevCommand = UIKeyCommand(input: "\t", modifierFlags: prevModifierFlags, action: prevAction)
    let nextCommand = UIKeyCommand(input: "\t", modifierFlags: nextModifierFlags, action: nextAction)
    return [prevCommand, nextCommand]
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    var viewControllers: [UIViewController] = [makeTabsController()]
    if traitCollection.userInterfaceIdiom == .phone, dependencies.launchService.didLaunchAfterInstall {
      viewControllers.append(makeWelcomeViewController())
    }

    var constraints: [NSLayoutConstraint] = []
    for viewController in viewControllers {
      addChild(viewController)
      view.addSubview(viewController.view)
      viewController.view.translatesAutoresizingMaskIntoConstraints = false
      viewController.didMove(toParent: self)

      constraints.append(contentsOf: [
        viewController.view.topAnchor.constraint(equalTo: view.topAnchor),
        viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      ])
    }

    NSLayoutConstraint.activate(constraints)

    view.backgroundColor = .fos_systemGroupedBackground

    dependencies.updateService.delegate = self
    dependencies.updateService.detectUpdates()
    dependencies.scheduleService?.startUpdating()
  }

  func applicationDidBecomeActive() {
    dependencies.liveService.startMonitoring()
    dependencies.scheduleService?.startUpdating()
  }

  func applicationWillResignActive() {
    dependencies.liveService.stopMonitoring()
  }

  @objc private func didSelectPrevTab() {
    if let rootTabBarController = tabsController {
      rootTabBarController.selectedIndex = ((rootTabBarController.selectedIndex - 1) + children.count) % children.count
    }
  }

  @objc private func didSelectNextTab() {
    if let rootTabBarController = tabsController {
      rootTabBarController.selectedIndex = ((rootTabBarController.selectedIndex + 1) + children.count) % children.count
    }
  }

  private func didTapUpdate() {
    if let url = URL.fosdemAppStore {
      UIApplication.shared.open(url)
    }
  }
}

private extension ApplicationController {
  func makeTabsController() -> UITabBarController {
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

  func makeSearchController() -> UIViewController {
    dependencies.navigationService.makeSearchViewController()
  }

  func makeAgendaController() -> UIViewController {
    dependencies.navigationService.makeAgendaViewController(didError: { [weak self] viewController, error in
      self?.agendaController(viewController, didError: error)
    })
  }

  func makeMapController() -> UIViewController {
    dependencies.navigationService.makeMapViewController(didError: { [weak self] viewController, error in
      self?.mapController(viewController, didError: error)
    })
  }

  func makeMoreController() -> UIViewController {
    dependencies.navigationService.makeMoreViewController()
  }

  func makeWelcomeViewController() -> WelcomeViewController {
    let welcomeViewController = WelcomeViewController(year: dependencies.yearsService.current)
    welcomeViewController.showsContinue = true
    welcomeViewController.delegate = self
    return welcomeViewController
  }

  func makeUpdateViewController() -> UIAlertController {
    UIAlertController.makeConfirmController(with: .update) { [weak self] in
      self?.didTapUpdate()
    }
  }
}

extension ApplicationController: UITabBarControllerDelegate {
  func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
    if viewController == tabBarController.selectedViewController {
      switch viewController {
      case let viewController as SearchController:
        viewController.popToRootViewController()
      case let viewController as AgendaController:
        viewController.popToRootViewController()
      case let viewController as MoreController:
        viewController.popToRootViewController()
      default:
        break
      }
    }

    return true
  }

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
      if let self = self {
        let updateViewController = self.makeUpdateViewController()
        self.present(updateViewController, animated: true)
      }
    }
  }
}

extension ApplicationController: WelcomeViewControllerDelegate {
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
