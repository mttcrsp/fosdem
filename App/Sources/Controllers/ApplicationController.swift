import UIKit

final class ApplicationController: UIViewController {
  typealias Dependencies = HasFavoritesService & HasLaunchService & HasNavigationService & HasOpenService & HasScheduleService & HasTimeService & HasUbiquitousPreferencesService & HasUpdateService & HasYearsService

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

    view.backgroundColor = .systemGroupedBackground

    dependencies.ubiquitousPreferencesService.startMonitoring()
    dependencies.favoritesService.startMonitoring()
    dependencies.scheduleService.startUpdating()
    dependencies.updateService.detectUpdates {
      DispatchQueue.main.async { [weak self] in
        if let self {
          let updateViewController = makeUpdateViewController()
          present(updateViewController, animated: true)
        }
      }
    }
  }

  func applicationDidBecomeActive() {
    dependencies.timeService.startMonitoring()
    dependencies.scheduleService.startUpdating()
  }

  func applicationWillResignActive() {
    dependencies.timeService.stopMonitoring()
  }

  @objc private func didSelectPrevTab() {
    if let rootTabBarController = tabsController {
      rootTabBarController.selectedIndex = ((rootTabBarController.selectedIndex - 1) + children.count) % children.count
      tabBarControllerDidChangeSelectedViewController(rootTabBarController)
    }
  }

  @objc private func didSelectNextTab() {
    if let rootTabBarController = tabsController {
      rootTabBarController.selectedIndex = ((rootTabBarController.selectedIndex + 1) + children.count) % children.count
      tabBarControllerDidChangeSelectedViewController(rootTabBarController)
    }
  }

  private func didTapUpdate() {
    if let url = URL.fosdemAppStore {
      dependencies.openService.open(url, completion: nil)
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
      tabBarControllerDidChangeSelectedViewController(tabsController)
    }

    self.tabsController = tabsController
    return tabsController
  }

  func makeSearchController() -> UIViewController {
    let searchViewController = dependencies.navigationService.makeSearchViewController()
    searchViewController.tabBarItem.accessibilityIdentifier = "search"
    searchViewController.tabBarItem.image = UIImage(systemName: "magnifyingglass")
    searchViewController.title = L10n.Search.title
    searchViewController.preferredDisplayMode = .oneBesideSecondary
    searchViewController.preferredPrimaryColumnWidthFraction = 0.4
    searchViewController.maximumPrimaryColumnWidth = 375
    return searchViewController
  }

  func makeAgendaController() -> UIViewController {
    let agendaViewController = dependencies.navigationService.makeAgendaViewController()
    agendaViewController.tabBarItem.accessibilityIdentifier = "agenda"
    agendaViewController.tabBarItem.image = UIImage(systemName: "calendar")
    agendaViewController.title = L10n.Agenda.title
    agendaViewController.didError = { [weak self] viewController, error in
      self?.agendaController(viewController, didError: error)
    }
    return agendaViewController
  }

  func makeMapController() -> UIViewController {
    let mapController = dependencies.navigationService.makeMapViewController()
    mapController.tabBarItem.accessibilityIdentifier = "map"
    mapController.tabBarItem.image = UIImage(systemName: "map")
    mapController.title = L10n.Map.title
    mapController.didError = { [weak self] viewController, error in
      self?.mapController(viewController, didError: error)
    }
    return mapController
  }

  func makeMoreController() -> UIViewController {
    let moreViewController = dependencies.navigationService.makeMoreViewController()
    moreViewController.tabBarItem.accessibilityIdentifier = "more"
    moreViewController.tabBarItem.image = UIImage(systemName: "ellipsis.circle")
    moreViewController.title = L10n.More.title
    moreViewController.preferredDisplayMode = .oneBesideSecondary
    moreViewController.preferredPrimaryColumnWidthFraction = 0.4
    moreViewController.maximumPrimaryColumnWidth = 375
    return moreViewController
  }

  func makeWelcomeViewController() -> WelcomeViewController {
    let welcomeViewController = WelcomeViewController(year: type(of: dependencies.yearsService).current)
    welcomeViewController.showsContinue = true
    welcomeViewController.delegate = self
    return welcomeViewController
  }

  func makeUpdateViewController() -> UIAlertController {
    let dismissAction = UIAlertAction(title: L10n.Update.dismiss, style: .cancel)
    let confirmAction = UIAlertAction(title: L10n.Update.confirm, style: .default) { [weak self] _ in self?.didTapUpdate() }
    let alertController = UIAlertController(title: L10n.Update.title, message: L10n.Update.message, preferredStyle: .alert)
    alertController.addAction(confirmAction)
    alertController.addAction(dismissAction)
    return alertController
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

  func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
    tabBarControllerDidChangeSelectedViewController(tabBarController)
    previouslySelectedViewController = String(describing: type(of: viewController))
  }

  func tabBarControllerDidChangeSelectedViewController(_ tabBarController: UITabBarController) {
    guard #available(iOS 15.0, *) else { return }

    if tabBarController.selectedViewController is MapController {
      let appearance = UITabBarAppearance()
      appearance.configureWithOpaqueBackground()
      tabBarController.tabBar.scrollEdgeAppearance = appearance
    } else {
      tabBarController.tabBar.scrollEdgeAppearance = nil
    }
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
