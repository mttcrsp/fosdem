import RIBs
import UIKit

protocol AgendaPresentableListener: AnyObject {
  func selectSoon()
  func select(_ event: Event?)
  func selectFirstEvent()
  func toggleFavorite(_ event: Event)
  func canFavoriteEvent(_ event: Event) -> Bool
  func isLive(_ event: Event) -> Bool
}

final class AgendaViewController: UIViewController {
  weak var listener: AgendaPresentableListener?

  var events: [Event] = [] {
    didSet { didChangeEvents() }
  }

  private weak var rootViewController: UIViewController? {
    didSet { didChangeRootViewController(from: oldValue, to: rootViewController) }
  }

  private weak var detailViewController: UIViewController?
  private weak var eventsViewController: EventsViewController?
}

extension AgendaViewController {
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass, traitCollection.horizontalSizeClass == .regular {
      if !showsDetailViewController, isViewLoaded {
        listener?.selectFirstEvent()
      }
    }
  }
}

extension AgendaViewController: AgendaPresentable {
  func insertEvent(at index: Int) {
    eventsViewController?.insertEvent(at: index)
  }

  func removeEvent(at index: Int) {
    eventsViewController?.deleteEvent(at: index)
  }

  func performEventsUpdate(_ updates: () -> Void) {
    eventsViewController?.performBatchUpdates(updates)
  }

  func reloadEvents() {
    eventsViewController?.reloadData()
  }

  func reloadLiveStatus() {
    eventsViewController?.reloadLiveStatus()
  }

  func showError() {
    let errorViewController = UIAlertController.makeErrorController()
    present(errorViewController, animated: true)
  }
}

extension AgendaViewController: AgendaViewControllable {
  func showDetail(_ viewControllable: ViewControllable) {
    let detailViewController = viewControllable.uiviewController
    self.detailViewController = detailViewController

    let navigationController = UINavigationController(rootViewController: detailViewController)
    eventsViewController?.showDetailViewController(navigationController, sender: nil)
    UIAccessibility.post(notification: .screenChanged, argument: navigationController.view)
  }

  func present(_ viewControllable: ViewControllable) {
    present(viewControllable.uiviewController, animated: true)
  }

  func dismiss(_ viewControllable: ViewControllable) {
    if presentedViewController === viewControllable.uiviewController {
      presentedViewController?.dismiss(animated: true)
    }
  }
}

extension AgendaViewController: EventsViewControllerDataSource {
  func events(in _: EventsViewController) -> [Event] {
    events
  }

  func eventsViewController(_: EventsViewController, captionFor event: Event) -> String? {
    [event.formattedStart, event.room, event.track].compactMap { $0 }.joined(separator: " - ")
  }
}

extension AgendaViewController: EventsViewControllerDelegate {
  func eventsViewController(_: EventsViewController, didSelect event: Event) {
    listener?.select(event)
  }
}

extension AgendaViewController: EventsViewControllerFavoritesDataSource {
  func eventsViewController(_: EventsViewController, canFavorite event: Event) -> Bool {
    listener?.canFavoriteEvent(event) ?? false
  }
}

extension AgendaViewController: EventsViewControllerFavoritesDelegate {
  func eventsViewController(_: EventsViewController, didToggleFavorite event: Event) {
    listener?.toggleFavorite(event)
  }
}

extension AgendaViewController: EventsViewControllerLiveDataSource {
  func eventsViewController(_: EventsViewController, shouldShowLiveIndicatorFor event: Event) -> Bool {
    listener?.isLive(event) ?? false
  }
}

private extension AgendaViewController {
  private var showsDetailViewController: Bool {
    detailViewController != nil
  }

  @objc func didTapSoon() {
    listener?.selectSoon()
  }

  func didChangeEvents() {
    if events.isEmpty, !(rootViewController is UINavigationController) {
      rootViewController = makeAgendaNavigationController()
      listener?.select(nil)
    } else if !events.isEmpty, !(rootViewController is UISplitViewController) {
      rootViewController = makeAgendaSplitViewController()
      if traitCollection.horizontalSizeClass == .regular {
        listener?.selectFirstEvent()
      }
    }
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

    let eventsViewController = EventsViewController(style: .grouped)
    eventsViewController.emptyBackgroundMessage = L10n.Agenda.Empty.message
    eventsViewController.emptyBackgroundTitle = L10n.Agenda.Empty.title
    eventsViewController.title = L10n.Agenda.title
    eventsViewController.navigationItem.largeTitleDisplayMode = .always
    eventsViewController.navigationItem.rightBarButtonItem = soonButton
    eventsViewController.favoritesDataSource = self
    eventsViewController.favoritesDelegate = self
    eventsViewController.liveDataSource = self
    eventsViewController.dataSource = self
    eventsViewController.delegate = self
    self.eventsViewController = eventsViewController

    let eventsNavigationController = UINavigationController(rootViewController: eventsViewController)
    eventsNavigationController.navigationBar.prefersLargeTitles = true
    return eventsNavigationController
  }
}
