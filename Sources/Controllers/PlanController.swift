import UIKit

protocol AgendaControllerDelegate: AnyObject {
    func agendaController(_ agendaController: AgendaController, didError error: Error)
}

final class AgendaController: UISplitViewController {
    weak var agendaDelegate: AgendaControllerDelegate?

    private weak var agendaViewController: EventsViewController?
    private weak var soonViewController: EventsViewController?

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

    private var now: Date {
        #if DEBUG
            return services.debugService.now
        #else
            return Date()
        #endif
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let agendaViewController = makeAgendaViewController()
        let agendaNavigationController = UINavigationController(rootViewController: agendaViewController)

        if #available(iOS 11.0, *) {
            agendaNavigationController.navigationBar.prefersLargeTitles = true
        }

        viewControllers = [agendaNavigationController]

        reloadFavoriteEvents()
        let observation1 = favoritesService.addObserverForEvents { [weak self] in
            self?.reloadFavoriteEvents()
        }

        let observation2 = services.liveService.addObserver { [weak self] in
            self?.reloadLiveStatus()
        }

        observations = [observation1, observation2]
    }

    private func reloadLiveStatus() {
        agendaViewController?.reloadLiveStatus()
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

    private func loadingDidFail(with error: Error) {
        agendaDelegate?.agendaController(self, didError: error)
    }

    private func loadingDidSucceed(with events: [Event]) {
        self.events = events

        agendaViewController?.reloadData()

        let isSingleChild = viewControllers.count == 1
        let isRegularSize = traitCollection.horizontalSizeClass == .regular
        let isDisplayingEmptyDetail = isSingleChild && isRegularSize

        if isDisplayingEmptyDetail, let event = events.first {
            agendaViewController?.select(event)

            let eventViewController = makeEventViewController(for: event)
            showDetailViewController(eventViewController, sender: nil)
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
    func makeEventViewController(for event: Event) -> EventController {
        EventController(event: event, favoritesService: favoritesService)
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
}
