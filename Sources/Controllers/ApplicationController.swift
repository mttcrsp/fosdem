import UIKit

final class ApplicationController: UITabBarController {
  private let services: Services

  init(services: Services) {
    self.services = services
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
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

    delegate = self

    var viewControllers: [UIViewController] = []
    viewControllers.append(makeSearchController())
    viewControllers.append(makeAgendaController())
    viewControllers.append(makeMapController())
    viewControllers.append(makeMoreController())
    setViewControllers(viewControllers, animated: false)

    for (index, viewController) in viewControllers.enumerated() where String(describing: type(of: viewController)) == previouslySelectedViewController {
      selectedIndex = index
    }

    services.updateService.delegate = self
    services.updateService.detectUpdates()
    services.scheduleService.startUpdating()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    if let crashService = services.crashService, crashService.hasPendingReport {
      present(makeCrashViewController(), animated: true)
    }
  }

  func applicationDidBecomeActive() {
    services.liveService.startMonitoring()
    services.scheduleService.startUpdating()
  }

  func applicationWillResignActive() {
    services.liveService.stopMonitoring()
  }

  private func didTapConfirmReport() {
    services.crashService?.uploadReport()
    services.crashService?.purgeReport()
  }

  private func didTapDismissReport() {
    services.crashService?.purgeReport()
  }

  private func didTapUpdate() {
    if let url = URL.fosdemAppStore {
      UIApplication.shared.open(url)
    }
  }

  @objc private func didSelectPrevTab() {
    selectedIndex = ((selectedIndex - 1) + children.count) % children.count
  }

  @objc private func didSelectNextTab() {
    selectedIndex = ((selectedIndex + 1) + children.count) % children.count
  }
}

private extension ApplicationController {
  func makeSearchController() -> SearchController {
    let searchController = SearchController(services: services)
    searchController.tabBarItem.accessibilityIdentifier = "search"
    searchController.tabBarItem.image = .fos_systemImage(withName: "magnifyingglass")
    searchController.title = NSLocalizedString("search.title", comment: "")
    searchController.preferredDisplayMode = .allVisible
    searchController.preferredPrimaryColumnWidthFraction = 0.4
    searchController.maximumPrimaryColumnWidth = 375
    return searchController
  }

  func makeAgendaController() -> AgendaController {
    let agendaController = AgendaController(services: services)
    agendaController.tabBarItem.accessibilityIdentifier = "agenda"
    agendaController.tabBarItem.image = .fos_systemImage(withName: "calendar")
    agendaController.title = NSLocalizedString("agenda.title", comment: "")
    agendaController.agendaDelegate = self
    return agendaController
  }

  func makeMapController() -> MapController {
    let mapController = MapController(services: services)
    mapController.tabBarItem.accessibilityIdentifier = "map"
    mapController.tabBarItem.image = .fos_systemImage(withName: "map")
    mapController.title = NSLocalizedString("map.title", comment: "")
    mapController.delegate = self
    return mapController
  }

  func makeMoreController() -> MoreController {
    let moreController = MoreController(services: services)
    moreController.tabBarItem.accessibilityIdentifier = "more"
    moreController.tabBarItem.image = .fos_systemImage(withName: "ellipsis.circle")
    moreController.title = NSLocalizedString("more.title", comment: "")
    moreController.preferredDisplayMode = .allVisible
    moreController.preferredPrimaryColumnWidthFraction = 0.4
    moreController.maximumPrimaryColumnWidth = 375
    return moreController
  }

  func makeUpdateViewController() -> UIAlertController {
    UIAlertController.makeConfirmController(with: .update) { [weak self] in
      self?.didTapUpdate()
    }
  }

  func makeCrashViewController() -> UIAlertController {
    let dismissHandler: () -> Void = { [weak self] in self?.didTapDismissReport() }
    let confirmHandler: () -> Void = { [weak self] in self?.didTapConfirmReport() }
    return UIAlertController.makeConfirmController(with: .crash, dismissHandler: dismissHandler, confirmHandler: confirmHandler)
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
    previouslySelectedViewController = String(describing: type(of: viewController))
  }
}

extension ApplicationController: AgendaControllerDelegate {
  func agendaController(_ agendaController: AgendaController, didError error: Error) {
    let errorViewController = ErrorViewController()
    agendaController.addChild(errorViewController)
    agendaController.view.addSubview(errorViewController.view)
    errorViewController.didMove(toParent: agendaController)
  }
}

extension ApplicationController: MapControllerDelegate {
  func mapController(_ mapController: MapController, didError error: Error) {
    let errorViewController = ErrorViewController()
    mapController.addChild(errorViewController)
    mapController.view.addSubview(errorViewController.view)
    errorViewController.didMove(toParent: mapController)
  }
}

extension ApplicationController: UpdateServiceDelegate {
  func updateServiceDidDetectUpdate(_ updateService: UpdateService) {
    DispatchQueue.main.async { [weak self] in
      if let self = self {
        let updateViewController = self.makeUpdateViewController()
        self.present(updateViewController, animated: true)
      }
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
      title: NSLocalizedString("update.title", comment: ""),
      message: NSLocalizedString("update.message", comment: ""),
      confirm: NSLocalizedString("update.confirm", comment: ""),
      dismiss: NSLocalizedString("update.dismiss", comment: "")
    )
  }

  static var crash: UIAlertController.ConfirmConfiguration {
    UIAlertController.ConfirmConfiguration(
      title: NSLocalizedString("crash.title", comment: ""),
      message: NSLocalizedString("crash.message", comment: ""),
      confirm: NSLocalizedString("crash.confirm", comment: ""),
      dismiss: NSLocalizedString("crash.dismiss", comment: "")
    )
  }
}
