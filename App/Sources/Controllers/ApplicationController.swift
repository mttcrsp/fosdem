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

    var tabViewControllers: [UIViewController] = []

    let searchViewController = dependencies.navigationService.makeSearchViewController()
    searchViewController.tabBarItem.accessibilityIdentifier = "search"
    searchViewController.tabBarItem.image = UIImage(systemName: "magnifyingglass")
    searchViewController.title = L10n.Search.title
    searchViewController.preferredDisplayMode = .oneBesideSecondary
    searchViewController.preferredPrimaryColumnWidthFraction = 0.4
    searchViewController.maximumPrimaryColumnWidth = 375
    tabViewControllers.append(searchViewController)

    let agendaViewController = dependencies.navigationService.makeAgendaViewController()
    agendaViewController.tabBarItem.accessibilityIdentifier = "agenda"
    agendaViewController.tabBarItem.image = UIImage(systemName: "calendar")
    agendaViewController.title = L10n.Agenda.title
    agendaViewController.didError = { [weak self] viewController, error in
      self?.agendaViewController(viewController, didError: error)
    }
    tabViewControllers.append(agendaViewController)

    let mapViewController = dependencies.navigationService.makeMapViewController()
    mapViewController.tabBarItem.accessibilityIdentifier = "map"
    mapViewController.tabBarItem.image = UIImage(systemName: "map")
    mapViewController.title = L10n.Map.title
    mapViewController.didError = { [weak self] viewController, error in
      self?.mapViewController(viewController, didError: error)
    }
    tabViewControllers.append(mapViewController)

    let moreViewController = dependencies.navigationService.makeMoreViewController()
    moreViewController.tabBarItem.accessibilityIdentifier = "more"
    moreViewController.tabBarItem.image = UIImage(systemName: "ellipsis.circle")
    moreViewController.title = L10n.More.title
    moreViewController.preferredDisplayMode = .oneBesideSecondary
    moreViewController.preferredPrimaryColumnWidthFraction = 0.4
    moreViewController.maximumPrimaryColumnWidth = 375
    tabViewControllers.append(moreViewController)

    let tabsController = UITabBarController()
    self.tabsController = tabsController
    tabsController.delegate = self
    tabsController.setViewControllers(tabViewControllers, animated: false)
    for (index, viewController) in tabViewControllers.enumerated() where String(describing: type(of: viewController)) == previouslySelectedViewController {
      tabsController.selectedIndex = index
      tabBarControllerDidChangeSelectedViewController(tabsController)
    }

    var viewControllers: [UIViewController] = [tabsController]
    if traitCollection.userInterfaceIdiom == .phone, dependencies.launchService.didLaunchAfterInstall {
      let welcomeViewController = WelcomeViewController(year: type(of: dependencies.yearsService).current)
      welcomeViewController.showsContinue = true
      welcomeViewController.delegate = self
      viewControllers.append(welcomeViewController)
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
        guard let self else { return }
        let dismissAction = UIAlertAction(title: L10n.Update.dismiss, style: .cancel)
        let confirmAction = UIAlertAction(title: L10n.Update.confirm, style: .default) { [weak self] _ in self?.didTapUpdate() }
        let alertController = UIAlertController(title: L10n.Update.title, message: L10n.Update.message, preferredStyle: .alert)
        alertController.addAction(confirmAction)
        alertController.addAction(dismissAction)
        present(alertController, animated: true)
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
}

private extension ApplicationController {
  @objc func didSelectPrevTab() {
    if let rootTabBarController = tabsController {
      rootTabBarController.selectedIndex = ((rootTabBarController.selectedIndex - 1) + children.count) % children.count
      tabBarControllerDidChangeSelectedViewController(rootTabBarController)
    }
  }

  @objc func didSelectNextTab() {
    if let rootTabBarController = tabsController {
      rootTabBarController.selectedIndex = ((rootTabBarController.selectedIndex + 1) + children.count) % children.count
      tabBarControllerDidChangeSelectedViewController(rootTabBarController)
    }
  }

  func didTapUpdate() {
    if let url = URL.fosdemAppStore {
      dependencies.openService.open(url, completion: nil)
    }
  }

  func agendaViewController(_ agendaViewController: UIViewController, didError _: Error) {
    let errorViewController = ErrorViewController()
    agendaViewController.addChild(errorViewController)
    agendaViewController.view.addSubview(errorViewController.view)
    errorViewController.didMove(toParent: agendaViewController)
  }

  func mapViewController(_ mapViewController: UIViewController, didError _: Error) {
    let errorViewController = ErrorViewController()
    mapViewController.addChild(errorViewController)
    mapViewController.view.addSubview(errorViewController.view)
    errorViewController.didMove(toParent: mapViewController)
  }
}

extension ApplicationController: UITabBarControllerDelegate {
  func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
    if viewController == tabBarController.selectedViewController {
      switch viewController {
      case let viewController as SearchViewController: viewController.popToRootViewController()
      case let viewController as AgendaViewController: viewController.popToRootViewController()
      case let viewController as MoreMainViewController: viewController.popToRootViewController()
      default: break
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

    if tabBarController.selectedViewController is MapMainViewController {
      let appearance = UITabBarAppearance()
      appearance.configureWithOpaqueBackground()
      tabBarController.tabBar.scrollEdgeAppearance = appearance
    } else {
      tabBarController.tabBar.scrollEdgeAppearance = nil
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
