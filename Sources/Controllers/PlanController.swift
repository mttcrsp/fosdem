import UIKit

final class PlanController: UISplitViewController {
    private weak var planViewController: EventsViewController?
    private weak var soonViewController: EventsViewController?

    private var observation: NSObjectProtocol?
    private var eventsStartingSoon: [Event] = []
    private var events: [Event] = []

    private let services: Services

    init(services: Services) {
        self.services = services
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var favoritesService: FavoritesService {
        services.favoritesService
    }

    private var persistenceService: PersistenceService {
        services.persistenceService
    }

    private var isDisplayingEmptyDetail: Bool {
        traitCollection.horizontalSizeClass == .regular && viewControllers.count == 1
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let planViewController = makePlanViewController()
        let planNavigationController = UINavigationController(rootViewController: planViewController)

        if #available(iOS 11.0, *) {
            planNavigationController.navigationBar.prefersLargeTitles = true
        }

        viewControllers = [planNavigationController]

        reloadFavoriteEvents()
        observation = favoritesService.addObserverForEvents { [weak self] in
            self?.reloadFavoriteEvents()
        }
    }

    private func reloadFavoriteEvents() {
        let identifiers = favoritesService.eventsIdentifiers
        let operation = EventsForIdentifiers(identifiers: identifiers)

        persistenceService.performRead(operation) { result in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case let .failure(error): self?.loadingDidFail(with: error)
                case let .success(events): self?.loadingDidSucceed(with: events)
                }
            }
        }
    }

    private func loadingDidFail(with _: Error) {
        viewControllers = [ErrorController()]
    }

    private func loadingDidSucceed(with events: [Event]) {
        self.events = events

        planViewController?.reloadData()
        if isDisplayingEmptyDetail, let event = events.first {
            planViewController?.select(event)

            let eventViewController = makeEventViewController(for: event)
            showDetailViewController(eventViewController, sender: nil)
        }
    }

    @objc private func didTapSoon() {
        #if DEBUG
            let now = services.debugService.now
        #else
            let now = Date()
        #endif

        let operation = EventsStartingIn30Minutes(now: now)
        persistenceService.performRead(operation) { result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                switch result {
                case .failure:
                    self.present(ErrorController(), animated: true)
                case let .success(events):
                    self.eventsStartingSoon = events
                    let soonViewController = self.makeSoonViewController()
                    let soonNavigationController = UINavigationController(rootViewController: soonViewController)
                    self.present(soonNavigationController, animated: true)
                }
            }
        }
    }

    @objc private func didTapDismiss() {
        soonViewController?.dismiss(animated: true)
    }
}

extension PlanController: EventsViewControllerDataSource, EventsViewControllerDelegate, EventsViewControllerFavoritesDataSource, EventsViewControllerFavoritesDelegate {
    func events(in eventsViewController: EventsViewController) -> [Event] {
        if eventsViewController == planViewController {
            return events
        } else if eventsViewController == soonViewController {
            return eventsStartingSoon
        } else {
            return []
        }
    }

    func eventsViewController(_ eventsViewController: EventsViewController, didSelect event: Event) {
        let eventViewController = makeEventViewController(for: event)

        if eventsViewController == soonViewController {
            eventsViewController.show(eventViewController, sender: nil)
        } else if eventsViewController == planViewController {
            eventsViewController.showDetailViewController(eventViewController, sender: nil)
        }
    }

    func eventsViewController(_: EventsViewController, canFavorite event: Event) -> Bool {
        !favoritesService.contains(event)
    }

    func eventsViewController(_: EventsViewController, didFavorite event: Event) {
        favoritesService.addEvent(withIdentifier: event.id)
    }

    func eventsViewController(_: EventsViewController, didUnfavorite event: Event) {
        favoritesService.removeEvent(withIdentifier: event.id)
    }
}

private extension PlanController {
    func makeEventViewController(for event: Event) -> EventController {
        EventController(event: event, favoritesService: favoritesService)
    }

    func makePlanViewController() -> EventsViewController {
        let soonTitle = NSLocalizedString("plan.soon", comment: "")
        let soonAction = #selector(didTapSoon)
        let soonButton = UIBarButtonItem(title: soonTitle, style: .plain, target: self, action: soonAction)

        let planViewController = EventsViewController(style: .grouped)
        planViewController.emptyBackgroundText = NSLocalizedString("plan.empty", comment: "")
        planViewController.title = NSLocalizedString("plan.title", comment: "")
        planViewController.navigationItem.rightBarButtonItem = soonButton
        planViewController.extendedLayoutIncludesOpaqueBars = true
        planViewController.favoritesDataSource = self
        planViewController.favoritesDelegate = self
        planViewController.dataSource = self
        planViewController.delegate = self
        self.planViewController = planViewController

        if #available(iOS 11.0, *) {
            planViewController.navigationItem.largeTitleDisplayMode = .always
        }

        return planViewController
    }

    func makeSoonViewController() -> EventsViewController {
        let dismissAction = #selector(didTapDismiss)
        let dismissButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: dismissAction)

        let soonViewController = EventsViewController(style: .grouped)
        soonViewController.emptyBackgroundText = NSLocalizedString("soon.empty", comment: "")
        soonViewController.title = NSLocalizedString("soon.title", comment: "")
        soonViewController.navigationItem.rightBarButtonItem = dismissButton
        soonViewController.favoritesDataSource = self
        soonViewController.favoritesDelegate = self
        soonViewController.dataSource = self
        soonViewController.delegate = self
        self.soonViewController = soonViewController
        return soonViewController
    }
}
