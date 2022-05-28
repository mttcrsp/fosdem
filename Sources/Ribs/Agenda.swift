import RIBs
import UIKit

protocol HasEventBuilder {
  var eventBuilder: EventBuildable { get }
}

typealias AgendaDependency =
  HasEventBuilder &
  HasFavoritesService &
  HasPersistenceService &
  HasTimeService &
  HasSoonService

protocol AgendaBuildable {
  func build(with listener: AgendaListener) -> ViewableRouting
}

final class AgendaBuilder: Builder<AgendaDependency>, AgendaBuildable {
  func build(with listener: AgendaListener) -> ViewableRouting {
    let viewController = _AgendaController()
    let interactor = AgendaInteractor(dependency: dependency, presenter: viewController)
    let router = AgendaRouter(interactor: interactor, viewController: viewController, eventBuilder: dependency.eventBuilder)

    interactor.router = router
    interactor.listener = listener
    viewController.listener = interactor
    return router
  }
}

protocol AgendaInteractable: Interactable {
  var router: AgendaRouting? { get set }
}

protocol AgendaListener: AnyObject {
  func didError(_ error: Error)
}

final class AgendaInteractor: PresentableInteractor<AgendaPresentable>, AgendaInteractable {
  weak var listener: AgendaListener?
  weak var router: AgendaRouting?

  private var favoritesObserver: NSObjectProtocol?
  private var timeObserver: NSObjectProtocol?

  let dependency: AgendaDependency

  init(dependency: AgendaDependency, presenter: AgendaPresentable) {
    self.dependency = dependency
    super.init(presenter: presenter)
  }

  deinit {
    if let favoritesObserver = favoritesObserver {
      dependency.favoritesService.removeObserver(favoritesObserver)
    }
  }

  override func didBecomeActive() {
    super.didBecomeActive()

    reloadFavoriteEvents()
    favoritesObserver = dependency.favoritesService.addObserverForEvents { [weak self] identifier in
      self?.reloadFavoriteEvents(forUpdateToEventWithIdentifier: identifier)
    }

    timeObserver = dependency.timeService.addObserver { [weak self] in
      self?.presenter.reloadLiveStatus()
    }
  }

  private func reloadFavoriteEvents(forUpdateToEventWithIdentifier identifier: Int? = nil) {
    let identifiers = dependency.favoritesService.eventsIdentifiers
    let operation = EventsForIdentifiers(identifiers: identifiers)
    dependency.persistenceService.performRead(operation) { result in
      DispatchQueue.main.async { [weak self] in
        switch result {
        case let .failure(error):
          self?.listener?.didError(error)
        case let .success(events):
          self?.presenter.showAgendaEvents(events, withUpdatedEventIdentifier: identifier)
        }
      }
    }
  }
}

extension AgendaInteractor: AgendaPresentableListener {
  func didSelectAgendaEvent(_ event: Event) {
    router?.routeToAgendaEvent(event)
  }

  func didSelectSoon() {
    dependency.soonService.loadEvents { result in
      DispatchQueue.main.async { [weak self] in
        switch result {
        case .failure:
          self?.presenter.showError()
        case let .success(events):
          self?.presenter.showSoonEvents(events)
        }
      }
    }
  }

  func didSelectSoonEvent(_ event: Event) {
    router?.routeToSoonEvent(event)
  }

  func didDeselectSoonEvent() {
    router?.routeToSoonEvent(nil)
  }

  func didFavorite(_ event: Event) {
    dependency.favoritesService.addEvent(withIdentifier: event.id)
  }

  func didUnfavorite(_ event: Event) {
    dependency.favoritesService.removeEvent(withIdentifier: event.id)
  }

  func canFavoritEvent(_ event: Event) -> Bool {
    !dependency.favoritesService.contains(event)
  }

  func shouldShowLiveIndicator(for event: Event) -> Bool {
    event.isLive(at: dependency.timeService.now)
  }
}

protocol AgendaRouting: Routing {
  func routeToAgendaEvent(_ event: Event)
  func routeToSoonEvent(_ event: Event?)
}

final class AgendaRouter: ViewableRouter<AgendaInteractable, AgendaViewControllable>, AgendaRouting {
  private var agendaEventRouter: ViewableRouting?
  private var soonEventRouter: ViewableRouting?

  private let eventBuilder: EventBuildable

  init(interactor: AgendaInteractable, viewController: AgendaViewControllable, eventBuilder: EventBuildable) {
    self.eventBuilder = eventBuilder
    super.init(interactor: interactor, viewController: viewController)
  }

  func routeToAgendaEvent(_ event: Event) {
    if let router = agendaEventRouter {
      detachChild(router)
      agendaEventRouter = nil
    }

    let router = eventBuilder.build(with: event)
    attachChild(router)
    viewController.showAgendaEvent(event, with: router.viewControllable)
    agendaEventRouter = router
  }

  func routeToSoonEvent(_ event: Event?) {
    if let event = event {
      let router = eventBuilder.build(with: event)
      attachChild(router)
      viewController.showSoonEvent(event, with: router.viewControllable)
      soonEventRouter = router
    } else if let router = soonEventRouter {
      detachChild(router)
      soonEventRouter = nil
    }
  }
}

protocol AgendaViewControllable: ViewControllable {
  func showAgendaEvent(_ event: Event, with viewControllable: ViewControllable)
  func showSoonEvent(_ event: Event, with viewControllable: ViewControllable)
}

protocol AgendaPresentable: Presentable {
  func reloadLiveStatus()
  func showError()
  func showSoonEvents(_ events: [Event])
  func showAgendaEvents(_ events: [Event], withUpdatedEventIdentifier identifier: Int?)
}

protocol AgendaPresentableListener: AnyObject {
  func didSelectSoon()
  func didSelectSoonEvent(_ event: Event)
  func didDeselectSoonEvent()
  func didSelectAgendaEvent(_ event: Event)
  func didFavorite(_ event: Event)
  func didUnfavorite(_ event: Event)
  func canFavoritEvent(_ event: Event) -> Bool
  func shouldShowLiveIndicator(for event: Event) -> Bool
}

final class _AgendaController: UIViewController {
  typealias Dependencies = HasNavigationService & HasFavoritesService & HasPersistenceService & HasTimeService & HasSoonService

  weak var listener: AgendaPresentableListener?

  private var agendaEvents: [Event] = []
  private var soonEvents: [Event] = []

  private weak var agendaViewController: EventsViewController?
  private weak var agendaNavigationController: UINavigationController?
  private weak var soonViewController: EventsViewController?
  private weak var soonNavigationController: UINavigationController?
  private weak var eventViewController: UIViewController?

  private weak var rootViewController: UIViewController? {
    didSet { didChangeRootViewController(from: oldValue, to: rootViewController) }
  }
}

extension _AgendaController: AgendaPresentable {
  func reloadLiveStatus() {
    agendaViewController?.reloadLiveStatus()
  }

  func showError() {
    let errorViewController = UIAlertController.makeErrorController()
    present(errorViewController, animated: true)
  }

  func showSoonEvents(_ soonEvents: [Event]) {
    self.soonEvents = soonEvents

    let soonNavigationController = makeSoonNavigationController()
    present(soonNavigationController, animated: true)
  }

  func showAgendaEvents(_ agendaEvents: [Event], withUpdatedEventIdentifier updatedEventID: Int?) {
    if agendaEvents.isEmpty, !(rootViewController is UINavigationController) {
      rootViewController = makeAgendaNavigationController()
    } else if !agendaEvents.isEmpty, !(rootViewController is UISplitViewController) {
      rootViewController = makeAgendaSplitViewController()
    }

    if let id = updatedEventID {
      let oldEvents = self.agendaEvents
      let newEvents = agendaEvents

      agendaViewController?.beginUpdates()
      self.agendaEvents = newEvents
      if let index = newEvents.firstIndex(where: { event in event.id == id }) {
        agendaViewController?.insertEvent(at: index)
      } else if let index = oldEvents.firstIndex(where: { event in event.id == id }) {
        agendaViewController?.deleteEvent(at: index)
      }
      agendaViewController?.endUpdates()
    } else {
      self.agendaEvents = agendaEvents
      agendaViewController?.reloadData()
    }

    var didDeleteSelectedEvent = false
    if let selectedEventID = eventViewController?.fos_eventID, !agendaEvents.contains(where: { event in event.id == selectedEventID }) {
      didDeleteSelectedEvent = true
    }

    if didDeleteSelectedEvent || isMissingSecondaryViewController {
      preselectFirstEvent()
    }
  }
}

extension _AgendaController: AgendaViewControllable {
  func showAgendaEvent(_ event: Event, with viewControllable: ViewControllable) {
    let eventViewController = viewControllable.uiviewController
    eventViewController.fos_eventID = event.id
    self.eventViewController = eventViewController

    agendaViewController?.showDetailViewController(eventViewController, sender: nil)
    UIAccessibility.post(notification: .screenChanged, argument: eventViewController.view)
  }

  func showSoonEvent(_ event: Event, with viewControllable: ViewControllable) {
    let eventViewController = viewControllable.uiviewController
    eventViewController.fos_eventID = event.id

    soonViewController?.show(eventViewController, sender: nil)
    soonViewController?.select(event)
  }
}

extension _AgendaController {
  private var isMissingSecondaryViewController: Bool {
    eventViewController == nil
  }

  func popToRootViewController() {
    if traitCollection.horizontalSizeClass == .compact {
      agendaViewController?.navigationController?.popToRootViewController(animated: true)
    }
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass, isMissingSecondaryViewController {
      preselectFirstEvent()
    }
  }

  @objc private func didTapSoon() {
    listener?.didSelectSoon()
  }

  @objc private func didTapDismiss() {
    soonViewController?.dismiss(animated: true)
  }

  private func didChangeRootViewController(from oldViewController: UIViewController?, to newViewController: UIViewController?) {
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
    if let event = agendaEvents.first, traitCollection.horizontalSizeClass == .regular {
      listener?.didSelectAgendaEvent(event)
    }
  }
}

extension _AgendaController: EventsViewControllerDataSource, EventsViewControllerDelegate {
  func events(in eventsViewController: EventsViewController) -> [Event] {
    switch eventsViewController {
    case agendaViewController:
      return agendaEvents
    case soonViewController:
      return soonEvents
    default:
      return []
    }
  }

  func eventsViewController(_ eventsViewController: EventsViewController, captionFor event: Event) -> String? {
    let items: [String?]

    switch eventsViewController {
    case agendaViewController:
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
      listener?.didSelectSoonEvent(event)
    case agendaViewController where eventViewController?.fos_eventID == event.id && traitCollection.horizontalSizeClass == .regular:
      break
    case agendaViewController:
      listener?.didSelectAgendaEvent(event)
    default:
      break
    }
  }
}

extension _AgendaController: EventsViewControllerFavoritesDataSource, EventsViewControllerFavoritesDelegate {
  func eventsViewController(_: EventsViewController, canFavorite event: Event) -> Bool {
    listener?.canFavoritEvent(event) ?? false
  }

  func eventsViewController(_: EventsViewController, didFavorite event: Event) {
    listener?.didFavorite(event)
  }

  func eventsViewController(_: EventsViewController, didUnfavorite event: Event) {
    listener?.didUnfavorite(event)
  }
}

extension _AgendaController: EventsViewControllerLiveDataSource {
  func eventsViewController(_: EventsViewController, shouldShowLiveIndicatorFor event: Event) -> Bool {
    if eventViewController == agendaViewController {
      return listener?.shouldShowLiveIndicator(for: event) ?? false
    } else {
      return false
    }
  }
}

extension _AgendaController: UINavigationControllerDelegate {
  func navigationController(_ navigationController: UINavigationController, didShow _: UIViewController, animated _: Bool) {
    if navigationController.viewControllers.count == 1, navigationController == soonNavigationController {
      listener?.didDeselectSoonEvent()
    }
  }
}

private extension _AgendaController {
  func makeAgendaSplitViewController() -> UISplitViewController {
    let agendaSplitViewController = UISplitViewController()
    agendaSplitViewController.viewControllers = [makeAgendaNavigationController()]
    agendaSplitViewController.preferredPrimaryColumnWidthFraction = 0.4
    agendaSplitViewController.preferredDisplayMode = .allVisible
    agendaSplitViewController.maximumPrimaryColumnWidth = 375
    return agendaSplitViewController
  }

  func makeAgendaNavigationController() -> UINavigationController {
    let soonTitle = L10n.Agenda.soon
    let soonAction = #selector(didTapSoon)
    let soonButton = UIBarButtonItem(title: soonTitle, style: .plain, target: self, action: soonAction)
    soonButton.accessibilityIdentifier = "soon"

    let agendaViewController = EventsViewController(style: .grouped)
    agendaViewController.emptyBackgroundMessage = L10n.Agenda.Empty.message
    agendaViewController.emptyBackgroundTitle = L10n.Agenda.Empty.title
    agendaViewController.title = L10n.Agenda.title
    agendaViewController.navigationItem.largeTitleDisplayMode = .always
    agendaViewController.navigationItem.rightBarButtonItem = soonButton
    agendaViewController.favoritesDataSource = self
    agendaViewController.favoritesDelegate = self
    agendaViewController.liveDataSource = self
    agendaViewController.dataSource = self
    agendaViewController.delegate = self
    self.agendaViewController = agendaViewController

    let agendaNavigationController = UINavigationController(rootViewController: agendaViewController)
    agendaNavigationController.navigationBar.prefersLargeTitles = true
    agendaNavigationController.delegate = self
    self.agendaNavigationController = agendaNavigationController

    return agendaNavigationController
  }

  func makeSoonNavigationController() -> UINavigationController {
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

    let soonNavigationController = UINavigationController(rootViewController: soonViewController)
    self.soonNavigationController = soonNavigationController

    return soonNavigationController
  }
}

private extension UIViewController {
  private static var eventIDKey = 0

  var fos_eventID: Int? {
    get { objc_getAssociatedObject(self, &UIViewController.eventIDKey) as? Int }
    set { objc_setAssociatedObject(self, &UIViewController.eventIDKey, newValue as Int?, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
  }
}
