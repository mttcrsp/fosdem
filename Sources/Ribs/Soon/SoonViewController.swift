import RIBs
import UIKit

protocol SoonPresentableListener: AnyObject {
  func select(_ event: Event?)
  func canFavorite(_ event: Event) -> Bool
  func toggleFavorite(_ event: Event)
  func dismiss()
}

final class SoonViewController: UINavigationController {
  weak var listener: SoonPresentableListener?

  var events: [Event] = [] {
    didSet { eventsViewController?.reloadData() }
  }

  private weak var eventsViewController: EventsViewController?

  init() {
    super.init(nibName: nil, bundle: nil)

    let dismissAction = #selector(didTapDismiss)
    let dismissButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: dismissAction)
    dismissButton.accessibilityIdentifier = "dismiss"

    let eventsViewController = EventsViewController(style: .grouped)
    eventsViewController.emptyBackgroundMessage = L10n.Soon.Empty.message
    eventsViewController.emptyBackgroundTitle = L10n.Soon.Empty.title
    eventsViewController.title = L10n.Soon.title
    eventsViewController.navigationItem.rightBarButtonItem = dismissButton
    eventsViewController.favoritesDataSource = self
    eventsViewController.favoritesDelegate = self
    eventsViewController.dataSource = self
    eventsViewController.delegate = self
    self.eventsViewController = eventsViewController

    delegate = self
    presentationController?.delegate = self
    viewControllers = [eventsViewController]
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension SoonViewController: SoonPresentable {}

extension SoonViewController: SoonViewControllable {
  func push(_ viewControllable: ViewControllable) {
    pushViewController(viewControllable.uiviewController, animated: true)
  }
}

extension SoonViewController: EventsViewControllerDataSource {
  func events(in _: EventsViewController) -> [Event] {
    events
  }

  func eventsViewController(_: EventsViewController, captionFor event: Event) -> String? {
    [event.formattedStart, event.room].compactMap { $0 }.joined(separator: " - ")
  }
}

extension SoonViewController: EventsViewControllerDelegate {
  func eventsViewController(_: EventsViewController, didSelect event: Event) {
    listener?.select(event)
  }
}

extension SoonViewController: EventsViewControllerFavoritesDataSource {
  func eventsViewController(_: EventsViewController, canFavorite event: Event) -> Bool {
    listener?.canFavorite(event) ?? false
  }
}

extension SoonViewController: EventsViewControllerFavoritesDelegate {
  func eventsViewController(_: EventsViewController, didToggleFavorite event: Event) {
    listener?.toggleFavorite(event)
  }
}

extension SoonViewController: UIAdaptivePresentationControllerDelegate {
  func presentationControllerDidDismiss(_: UIPresentationController) {
    listener?.dismiss()
  }
}

extension SoonViewController: UINavigationControllerDelegate {
  func navigationController(_: UINavigationController, didShow viewController: UIViewController, animated _: Bool) {
    if viewController == eventsViewController {
      listener?.select(nil as Event?)
    }
  }
}

private extension SoonViewController {
  @objc func didTapDismiss() {
    listener?.dismiss()
  }
}
