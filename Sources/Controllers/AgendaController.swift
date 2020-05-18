import UIKit

protocol AgendaControllerDelegate: AnyObject {
    func agendaController(_ agendaController: AgendaController, didError error: Error)
}

final class AgendaController: UIViewController {
    weak var agendaDelegate: AgendaControllerDelegate?

    private weak var agendaSplitViewController: UISplitViewController?
    private weak var agendaViewController: EventsViewController?
    private weak var soonViewController: EventsViewController?
    private weak var eventViewController: EventController?

    private weak var rootViewController: UIViewController? {
        didSet { didChangeRootViewController(from: oldValue, to: rootViewController) }
    }

    private var observations: [NSObjectProtocol] = []
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

    private var isMissingSecondaryViewController: Bool {
        eventViewController == nil
    }

    private var now: Date {
        #if DEBUG
            return services.debugService.now
        #else
            return Date()
        #endif
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        reloadFavoriteEvents()
        let observation1 = favoritesService.addObserverForEvents { [weak self] in
            self?.reloadFavoriteEvents()
        }

        let observation2 = services.liveService.addObserver { [weak self] in
            self?.reloadLiveStatus()
        }

        observations = [observation1, observation2]
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass, isMissingSecondaryViewController {
            preselectFirstEvent()
        }
    }

    private func reloadLiveStatus() {
        agendaViewController?.reloadLiveStatus()
    }

    private func reloadFavoriteEvents() {
        let identifiers = favoritesService.eventsIdentifiers

        if identifiers.isEmpty, !(rootViewController is UINavigationController) {
            rootViewController = makeAgendaNavigationController()
        } else if !identifiers.isEmpty, !(rootViewController is UISplitViewController) {
            rootViewController = makeAgendaSplitViewController()
        }

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

    private func loadingDidFail(with error: Error) {
        agendaDelegate?.agendaController(self, didError: error)
    }

    private func loadingDidSucceed(with events: [Event]) {
        self.events = events
        agendaViewController?.reloadData()

        var didDeleteSelectedEvent = false
        if let selectedEvent = eventViewController?.event, !events.contains(selectedEvent) {
            didDeleteSelectedEvent = true
        }

        if didDeleteSelectedEvent || isMissingSecondaryViewController {
            preselectFirstEvent()
        }
    }

    @objc private func didTapSoon() {
        let operation = EventsStartingIn30Minutes(now: now)
        persistenceService.performRead(operation) { result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                switch result {
                case .failure:
                    let errorViewController = UIAlertController.makeErrorController()
                    self.present(errorViewController, animated: true)
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

    func didChangeRootViewController(from oldViewController: UIViewController?, to newViewController: UIViewController?) {
        if let viewController = oldViewController {
            viewController.willMove(toParent: nil)
            viewController.view.removeFromSuperview()
            viewController.removeFromParent()
        }

        if let viewController = newViewController {
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
    }

    private func preselectFirstEvent() {
        if let event = events.first, traitCollection.horizontalSizeClass == .regular {
            let eventViewController = makeEventViewController(for: event)
            agendaViewController?.showDetailViewController(eventViewController, sender: nil)
            agendaViewController?.select(event)
        }
    }
}

extension AgendaController: EventsViewControllerDataSource, EventsViewControllerDelegate, EventsViewControllerFavoritesDataSource, EventsViewControllerFavoritesDelegate, EventsViewControllerLiveDataSource {
    func events(in eventsViewController: EventsViewController) -> [Event] {
        switch eventsViewController {
        case agendaViewController: return events
        case soonViewController: return eventsStartingSoon
        default: return []
        }
    }

    func eventsViewController(_ eventsViewController: EventsViewController, captionFor event: Event) -> String? {
        let items: [String?]

        switch eventsViewController {
        case agendaViewController: items = [event.formattedStart, event.room, event.track]
        case soonViewController: items = [event.formattedStart, event.room]
        default: return nil
        }

        return items.compactMap { $0 }.joined(separator: " - ")
    }

    func eventsViewController(_ eventsViewController: EventsViewController, didSelect event: Event) {
        let eventViewController = makeEventViewController(for: event)

        switch eventsViewController {
        case agendaViewController: eventsViewController.showDetailViewController(eventViewController, sender: nil)
        case soonViewController: eventsViewController.show(eventViewController, sender: nil)
        default: break
        }
    }

    func eventsViewController(_ eventsViewController: EventsViewController, shouldShowLiveIndicatorFor event: Event) -> Bool {
        eventsViewController == agendaViewController && event.isLive(at: now)
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

private extension AgendaController {
    func makeAgendaSplitViewController() -> UISplitViewController {
        let agendaSplitViewController = UISplitViewController()
        agendaSplitViewController.viewControllers = [makeAgendaNavigationController()]
        agendaSplitViewController.preferredPrimaryColumnWidthFraction = 0.4
        agendaSplitViewController.preferredDisplayMode = .allVisible
        agendaSplitViewController.maximumPrimaryColumnWidth = 375
        self.agendaSplitViewController = agendaSplitViewController
        return agendaSplitViewController
    }

    func makeAgendaNavigationController() -> UINavigationController {
        let agendaViewController = makeAgendaViewController()
        let agendaNavigationController = UINavigationController(rootViewController: agendaViewController)

        if #available(iOS 11.0, *) {
            agendaNavigationController.navigationBar.prefersLargeTitles = true
        }

        return agendaNavigationController
    }

    func makeAgendaViewController() -> EventsViewController {
        let soonTitle = NSLocalizedString("agenda.soon", comment: "")
        let soonAction = #selector(didTapSoon)
        let soonButton = UIBarButtonItem(title: soonTitle, style: .plain, target: self, action: soonAction)

        let agendaViewController = EventsViewController(style: .grouped)
        agendaViewController.emptyBackgroundMessage = NSLocalizedString("agenda.empty.message", comment: "")
        agendaViewController.emptyBackgroundTitle = NSLocalizedString("agenda.empty.title", comment: "")
        agendaViewController.title = NSLocalizedString("agenda.title", comment: "")
        agendaViewController.navigationItem.rightBarButtonItem = soonButton
        agendaViewController.favoritesDataSource = self
        agendaViewController.favoritesDelegate = self
        agendaViewController.liveDataSource = self
        agendaViewController.dataSource = self
        agendaViewController.delegate = self
        self.agendaViewController = agendaViewController

        if #available(iOS 11.0, *) {
            agendaViewController.navigationItem.largeTitleDisplayMode = .always
        }

        return agendaViewController
    }

    func makeSoonViewController() -> EventsViewController {
        let dismissAction = #selector(didTapDismiss)
        let dismissButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: dismissAction)

        let soonViewController = EventsViewController(style: .grouped)
        soonViewController.emptyBackgroundMessage = NSLocalizedString("soon.empty.message", comment: "")
        soonViewController.emptyBackgroundTitle = NSLocalizedString("soon.empty.title", comment: "")
        soonViewController.title = NSLocalizedString("soon.title", comment: "")
        soonViewController.navigationItem.rightBarButtonItem = dismissButton
        soonViewController.favoritesDataSource = self
        soonViewController.favoritesDelegate = self
        soonViewController.dataSource = self
        soonViewController.delegate = self
        self.soonViewController = soonViewController
        return soonViewController
    }

    func makeEventViewController(for event: Event) -> EventController {
        let eventViewController = EventController(event: event, favoritesService: favoritesService)
        self.eventViewController = eventViewController
        return eventViewController
    }
}
