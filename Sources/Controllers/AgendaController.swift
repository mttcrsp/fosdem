import UIKit

final class AgendaController {
  typealias Dependencies = HasNavigationService & HasFavoritesService & HasPersistenceService & HasTimeService & HasSoonService

  var didError: ((UIViewController, Error) -> Void)?

  private weak var agendaChildViewController: EventsViewController?
  private weak var parentViewController: ParentViewController?
  private weak var soonViewController: EventsViewController?
  private weak var eventViewController: UIViewController?

  private var observations: [NSObjectProtocol] = []
  private var eventsStartingSoon: [Event] = []
  private var events: [Event] = []

  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies

    observations = [
      dependencies.favoritesService.addObserverForEvents { [weak self] identifier in
        self?.reloadFavoriteEvents(forUpdateToEventWithIdentifier: identifier)
      },
      dependencies.timeService.addObserver { [weak self] in
        self?.reloadLiveStatus()
      },
    ]
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private var isMissingSecondaryViewController: Bool {
    eventViewController == nil
  }

  func reloadData() {
    reloadFavoriteEvents()
    reloadFavoriteEvents()
  }

  private func reloadLiveStatus() {
    agendaChildViewController?.reloadLiveStatus()
  }

  private func reloadFavoriteEvents(forUpdateToEventWithIdentifier identifier: Int? = nil) {
    guard let parentViewController = parentViewController else { return }

    let identifiers = dependencies.favoritesService.eventsIdentifiers

    let rootViewController = parentViewController.childViewController
    if identifiers.isEmpty, !(rootViewController is UINavigationController) {
      parentViewController.setChild(makeAgendaNavigationController())
    } else if !identifiers.isEmpty, !(rootViewController is UISplitViewController) {
      parentViewController.setChild(makeAgendaSplitViewController())
    }

    let operation = EventsForIdentifiers(identifiers: identifiers)
    dependencies.persistenceService.performRead(operation) { result in
      DispatchQueue.main.async { [weak self] in
        switch result {
        case let .failure(error):
          self?.loadingDidFail(with: error)
        case let .success(events):
          self?.loadingDidSucceed(with: events, updatedEventIdentifier: identifier)
        }
      }
    }
  }

  private func loadingDidFail(with error: Error) {
    if let parentViewController = parentViewController {
      didError?(parentViewController, error)
    }
  }

  private func loadingDidSucceed(with events: [Event], updatedEventIdentifier: Int?) {
    if let id = updatedEventIdentifier {
      let oldEvents = self.events
      let newEvents = events

      agendaChildViewController?.beginUpdates()
      self.events = newEvents
      if let index = newEvents.firstIndex(where: { event in event.id == id }) {
        agendaChildViewController?.insertEvent(at: index)
      } else if let index = oldEvents.firstIndex(where: { event in event.id == id }) {
        agendaChildViewController?.deleteEvent(at: index)
      }
      agendaChildViewController?.endUpdates()
    } else {
      self.events = events
      agendaChildViewController?.reloadData()
    }

    var didDeleteSelectedEvent = false
    if let selectedEventID = eventViewController?.fos_eventID, !events.contains(where: { event in event.id == selectedEventID }) {
      didDeleteSelectedEvent = true
    }

    if didDeleteSelectedEvent || isMissingSecondaryViewController {
      preselectFirstEvent()
    }
  }

  @objc private func didTapSoon() {
    dependencies.soonService.loadEvents { result in
      DispatchQueue.main.async { [weak self] in
        guard let self = self, let parentViewController = self.parentViewController else { return }

        switch result {
        case .failure:
          let errorViewController = UIAlertController.makeErrorController()
          parentViewController.present(errorViewController, animated: true)
        case let .success(events):
          self.eventsStartingSoon = events
          let soonViewController = self.makeSoonViewController()
          let soonNavigationController = UINavigationController(rootViewController: soonViewController)
          parentViewController.present(soonNavigationController, animated: true)
        }
      }
    }
  }

  @objc private func didTapDismiss() {
    soonViewController?.dismiss(animated: true)
  }

  private func preselectFirstEvent() {
    if let event = events.first, parentViewController?.traitCollection.horizontalSizeClass == .regular {
      let eventViewController = makeEventViewController(for: event)
      agendaChildViewController?.showDetailViewController(eventViewController, sender: nil)
      agendaChildViewController?.select(event)
    }
  }
}

extension AgendaController: ParentViewControllerDelegate {
  func parentViewController(_ parentViewController: UIViewController, didChangeTraitCollectionFrom previousTraitCollection: UITraitCollection?) {
    if parentViewController.traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass, isMissingSecondaryViewController {
      preselectFirstEvent()
    }
  }
}

extension AgendaController: EventsViewControllerDataSource, EventsViewControllerDelegate {
  func events(in eventsViewController: EventsViewController) -> [Event] {
    switch eventsViewController {
    case agendaChildViewController:
      return events
    case soonViewController:
      return eventsStartingSoon
    default:
      return []
    }
  }

  func eventsViewController(_ eventsViewController: EventsViewController, captionFor event: Event) -> String? {
    let items: [String?]

    switch eventsViewController {
    case agendaChildViewController:
      items = [event.formattedStart, event.room, event.track]
    case soonViewController:
      items = [event.formattedStart, event.room]
    default:
      return nil
    }

    return items.compactMap { $0 }.joined(separator: " - ")
  }

  func eventsViewController(_ eventsViewController: EventsViewController, didSelect event: Event) {
    switch eventsViewController {
    case soonViewController:
      let eventViewController = makeSoonEventViewController(for: event)
      eventsViewController.show(eventViewController, sender: nil)
    case agendaChildViewController where eventViewController?.fos_eventID == event.id && parentViewController?.traitCollection.horizontalSizeClass == .regular:
      break
    case agendaChildViewController:
      let eventViewController = makeEventViewController(for: event)
      eventsViewController.showDetailViewController(eventViewController, sender: nil)
      UIAccessibility.post(notification: .screenChanged, argument: eventViewController.view)
    default:
      break
    }
  }
}

extension AgendaController: EventsViewControllerFavoritesDataSource, EventsViewControllerFavoritesDelegate {
  func eventsViewController(_: EventsViewController, canFavorite event: Event) -> Bool {
    !dependencies.favoritesService.contains(event)
  }

  func eventsViewController(_: EventsViewController, didFavorite event: Event) {
    dependencies.favoritesService.addEvent(withIdentifier: event.id)
  }

  func eventsViewController(_: EventsViewController, didUnfavorite event: Event) {
    dependencies.favoritesService.removeEvent(withIdentifier: event.id)
  }
}

extension AgendaController: EventsViewControllerLiveDataSource {
  func eventsViewController(_ eventsViewController: EventsViewController, shouldShowLiveIndicatorFor event: Event) -> Bool {
    eventsViewController == agendaChildViewController && event.isLive(at: dependencies.timeService.now)
  }
}

extension AgendaController {
  func makeAgendaViewController() -> ParentViewController {
    let parentViewController = ParentViewController()
    self.parentViewController = parentViewController
    parentViewController.delegate = self
    return parentViewController
  }

  private func makeAgendaSplitViewController() -> UISplitViewController {
    let agendaSplitViewController = UISplitViewController()
    agendaSplitViewController.viewControllers = [makeAgendaNavigationController()]
    agendaSplitViewController.preferredPrimaryColumnWidthFraction = 0.4
    #if targetEnvironment(macCatalyst)
    agendaSplitViewController.preferredDisplayMode = .oneBesideSecondary
    #else
    agendaSplitViewController.preferredDisplayMode = .allVisible
    #endif
    agendaSplitViewController.maximumPrimaryColumnWidth = 375
    return agendaSplitViewController
  }

  private func makeAgendaNavigationController() -> UINavigationController {
    let agendaViewController = makeAgendaChildViewController()
    let agendaNavigationController = UINavigationController(rootViewController: agendaViewController)
    agendaNavigationController.navigationBar.prefersLargeTitles = true
    return agendaNavigationController
  }

  private func makeAgendaChildViewController() -> EventsViewController {
    let soonTitle = L10n.Agenda.soon
    let soonAction = #selector(didTapSoon)
    let soonButton = UIBarButtonItem(title: soonTitle, style: .plain, target: self, action: soonAction)
    soonButton.accessibilityIdentifier = "soon"

    let agendaChildViewController = EventsViewController(style: .grouped)
    agendaChildViewController.emptyBackgroundMessage = L10n.Agenda.Empty.message
    agendaChildViewController.emptyBackgroundTitle = L10n.Agenda.Empty.title
    agendaChildViewController.title = L10n.Agenda.title
    agendaChildViewController.navigationItem.largeTitleDisplayMode = .always
    agendaChildViewController.navigationItem.rightBarButtonItem = soonButton
    agendaChildViewController.favoritesDataSource = self
    agendaChildViewController.favoritesDelegate = self
    agendaChildViewController.liveDataSource = self
    agendaChildViewController.dataSource = self
    agendaChildViewController.delegate = self
    self.agendaChildViewController = agendaChildViewController
    return agendaChildViewController
  }

  private func makeSoonViewController() -> EventsViewController {
    let dismissAction = #selector(didTapDismiss)
    let dismissButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: dismissAction)
    dismissButton.accessibilityIdentifier = "dismiss"

    let soonViewController = EventsViewController(style: .grouped)
    soonViewController.emptyBackgroundMessage = L10n.Soon.Empty.message
    soonViewController.emptyBackgroundTitle = L10n.Soon.Empty.title
    soonViewController.title = L10n.Soon.title
    soonViewController.navigationItem.rightBarButtonItem = dismissButton
    soonViewController.favoritesDataSource = self
    soonViewController.favoritesDelegate = self
    soonViewController.dataSource = self
    soonViewController.delegate = self
    self.soonViewController = soonViewController
    return soonViewController
  }

  private func makeEventViewController(for event: Event) -> UIViewController {
    let eventViewController = dependencies.navigationService.makeEventViewController(for: event)
    eventViewController.fos_eventID = event.id
    self.eventViewController = eventViewController
    return eventViewController
  }

  private func makeSoonEventViewController(for event: Event) -> UIViewController {
    let eventViewController = dependencies.navigationService.makeEventViewController(for: event)
    eventViewController.fos_eventID = event.id
    return eventViewController
  }
}

private extension UIViewController {
  private static var eventIDKey = 0

  var fos_eventID: Int? {
    get { objc_getAssociatedObject(self, &UIViewController.eventIDKey) as? Int }
    set { objc_setAssociatedObject(self, &UIViewController.eventIDKey, newValue as Int?, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
  }
}
