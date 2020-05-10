import UIKit

final class ApplicationController: UITabBarController {
    private let services: Services

    init(services: Services) {
        self.services = services
        super.init(nibName: nil, bundle: nil)
    }

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
        let prevAction = #selector(didSelectPrevTab(_:))
        let nextAction = #selector(didSelectNextTab(_:))
        let prevCommand = UIKeyCommand(input: "\t", modifierFlags: prevModifierFlags, action: prevAction)
        let nextCommand = UIKeyCommand(input: "\t", modifierFlags: nextModifierFlags, action: nextAction)
        return [prevCommand, nextCommand]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        var viewControllers: [UIViewController] = []
        viewControllers.append(makeSearchController())
        viewControllers.append(makePlanController())
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

    func applicationDidBecomeActive() {
        services.liveService.startMonitoring()
        services.scheduleService.startUpdating()
    }

    func applicationWillResignActive() {
        services.liveService.stopMonitoring()
    }

    @objc private func didSelectPrevTab(_: Any) {
        selectedIndex = ((selectedIndex - 1) + children.count) % children.count
    }

    @objc private func didSelectNextTab(_: Any) {
        selectedIndex = ((selectedIndex + 1) + children.count) % children.count
    }
}

private extension ApplicationController {
    func makePlanController() -> PlanController {
        let planController = PlanController(services: services)
        planController.tabBarItem.image = .fos_systemImage(withName: "calendar")
        planController.title = NSLocalizedString("plan.title", comment: "")
        planController.preferredDisplayMode = .allVisible
        return planController
    }

    func makeSearchController() -> SearchController {
        let searchController = SearchController(services: services)
        searchController.tabBarItem.image = .fos_systemImage(withName: "magnifyingglass")
        searchController.title = NSLocalizedString("search.title", comment: "")
        searchController.preferredDisplayMode = .allVisible
        return searchController
    }

    func makeMapController() -> MapController {
        let mapController = MapController(services: services)
        mapController.tabBarItem.image = .fos_systemImage(withName: "map")
        mapController.title = NSLocalizedString("map.title", comment: "")
        return mapController
    }

    func makeMoreController() -> MoreController {
        let moreController = MoreController(services: services)
        moreController.tabBarItem.image = .fos_systemImage(withName: "ellipsis.circle")
        moreController.title = NSLocalizedString("more.title", comment: "")
        moreController.preferredDisplayMode = .allVisible
        return moreController
    }

    func makeUpdateViewController(withHandler handler: @escaping () -> Void) -> UIAlertController {
        let dismissTitle = NSLocalizedString("update.dismiss", comment: "")
        let dismissAction = UIAlertAction(title: dismissTitle, style: .cancel)

        let confirmTitle = NSLocalizedString("update.confirm", comment: "")
        let confirmAction = UIAlertAction(title: confirmTitle, style: .default) { _ in handler() }

        let alertTitle = NSLocalizedString("update.title", comment: "")
        let alertMessage = NSLocalizedString("update.message", comment: "")
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        alertController.addAction(confirmAction)
        alertController.addAction(dismissAction)
        return alertController
    }
}

extension ApplicationController: UITabBarControllerDelegate {
    func tabBarController(_: UITabBarController, didSelect viewController: UIViewController) {
        previouslySelectedViewController = String(describing: type(of: viewController))
    }
}

extension ApplicationController: UpdateServiceDelegate {
    func updateServiceDidDetectUpdate(_: UpdateService) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let updateHandler: () -> Void = { [weak self] in self?.didTapUpdate() }
            let updateViewController = self.makeUpdateViewController(withHandler: updateHandler)
            self.present(updateViewController, animated: true)
        }
    }

    private func didTapUpdate() {
        if let url = URL(string: "https://itunes.apple.com/it/app/id1477376905") {
            UIApplication.shared.open(url)
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
