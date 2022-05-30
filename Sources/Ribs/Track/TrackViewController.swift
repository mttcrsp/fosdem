import RIBs
import UIKit

protocol TrackPresentableListener: AnyObject {
  func select(_ event: Event)
  func deselectEvent()
  func canFavorite(_ event: Event) -> Bool
  func toggleFavorite()
  func toggleFavorite(_ event: Event)
}

final class TrackViewController: UINavigationController {
  weak var listener: TrackPresentableListener?

  var track: Track? {
    didSet { title = track?.name }
  }

  var events: [Event] = [] {
    didSet { didChangeEvents() }
  }

  var showsFavorite = false {
    didSet { didChangeShowsFavorite() }
  }

  private var eventsCaptions: [Event: String] = [:]

  private weak var favoriteButton: UIBarButtonItem?
  private weak var eventViewController: UIViewController?
  private weak var eventsViewController: EventsViewController?

  init() {
    super.init(nibName: nil, bundle: nil)

    var style = UITableView.Style.grouped
    if traitCollection.userInterfaceIdiom == .pad {
      style = .fos_insetGrouped
    }

    let favoriteAction = #selector(didToggleFavorite)
    let favoriteButton = UIBarButtonItem(title: nil, style: .plain, target: self, action: favoriteAction)
    self.favoriteButton = favoriteButton

    let eventsViewController = EventsViewController(style: style)
    eventsViewController.navigationItem.rightBarButtonItem = favoriteButton
    eventsViewController.favoritesDataSource = self
    eventsViewController.favoritesDelegate = self
    eventsViewController.dataSource = self
    eventsViewController.delegate = self
    self.eventsViewController = eventsViewController

    viewControllers = [eventsViewController]
    delegate = self
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension TrackViewController: TrackPresentable {}

extension TrackViewController: TrackViewControllable {
  func show(_ viewControllable: ViewControllable) {
    show(viewControllable.uiviewController, sender: nil)
  }
}

extension TrackViewController: EventsViewControllerDataSource {
  func events(in _: EventsViewController) -> [Event] {
    events
  }

  func eventsViewController(_: EventsViewController, captionFor event: Event) -> String? {
    eventsCaptions[event]
  }
}

extension TrackViewController: EventsViewControllerDelegate {
  func eventsViewController(_: EventsViewController, didSelect event: Event) {
    listener?.select(event)
  }
}

extension TrackViewController: EventsViewControllerFavoritesDataSource {
  func eventsViewController(_: EventsViewController, canFavorite event: Event) -> Bool {
    listener?.canFavorite(event) ?? false
  }
}

extension TrackViewController: EventsViewControllerFavoritesDelegate {
  func eventsViewController(_: EventsViewController, didToggleFavorite event: Event) {
    listener?.toggleFavorite(event)
  }
}

extension TrackViewController: UINavigationControllerDelegate {
  func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated _: Bool) {
    if !navigationController.viewControllers.contains(where: { viewController in viewController === eventViewController }) {
      listener?.deselectEvent()
    }
  }
}

private extension TrackViewController {
  @objc func didToggleFavorite() {
    listener?.toggleFavorite()
  }

  func didChangeEvents() {
    eventsCaptions = events.captions
    eventsViewController?.reloadData()
  }

  func didChangeShowsFavorite() {
    favoriteButton?.title = showsFavorite ? L10n.unfavorite : L10n.favorite
    favoriteButton?.accessibilityIdentifier = showsFavorite ? "unfavorite" : "favorite"
  }
}

private extension Array where Element == Event {
  var captions: [Event: String] {
    var result: [Event: String] = [:]

    if let event = first, let caption = event.formattedStartWithWeekday {
      result[event] = caption
    }

    for (lhs, rhs) in zip(self, dropFirst()) {
      if lhs.isSameWeekday(as: rhs) {
        if let caption = rhs.formattedStart {
          result[rhs] = caption
        }
      } else {
        if let caption = rhs.formattedStartWithWeekday {
          result[rhs] = caption
        }
      }
    }

    return result
  }
}
