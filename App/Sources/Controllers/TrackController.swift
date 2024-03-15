import UIKit

final class TrackController: EventsViewController {
  typealias Dependencies = HasFavoritesService & HasNavigationService & HasPersistenceService

  var didError: NavigationService.ErrorHandler?

  private var favoriteButton: UIBarButtonItem?

  private var captions: [Event: String] = [:]
  private var events: [Event] = []
  private var observer: NSObjectProtocol?

  private let dependencies: Dependencies
  private let track: Track

  init(track: Track, style: UITableView.Style, dependencies: Dependencies) {
    self.dependencies = dependencies
    self.track = track
    super.init(style: style)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func load(_ completion: @escaping (Error?) -> Void) {
    dependencies.persistenceService.performRead(GetEventsByTrack(track: track.name)) { result in
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }

        switch result {
        case let .failure(error):
          completion(error)
        case let .success(events):
          self.events = events
          captions = events.captions
          completion(nil)
        }
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    dataSource = self
    delegate = self
    favoritesDataSource = self
    favoritesDelegate = self

    let title = track.formattedName
    self.title = title

    let favoriteAction = #selector(didToggleFavorite)
    let favoriteButton = UIBarButtonItem(title: nil, style: .plain, target: self, action: favoriteAction)
    self.favoriteButton = favoriteButton
    navigationItem.rightBarButtonItem = favoriteButton
    navigationItem.largeTitleDisplayMode = prefersLargeTitle(forTitle: title) ? .always : .never

    reloadFavoriteButton()
    observer = dependencies.favoritesService.addObserverForTracks { [weak self] in
      self?.reloadFavoriteButton()
    }
  }

  private func reloadFavoriteButton() {
    let isFavorite = dependencies.favoritesService.contains(track)
    favoriteButton?.accessibilityIdentifier = isFavorite ? "unfavorite" : "favorite"
    favoriteButton?.title = isFavorite ? L10n.unfavorite : L10n.favorite
  }

  private func prefersLargeTitle(forTitle title: String) -> Bool {
    let font = UIFont.fos_preferredFont(forTextStyle: .largeTitle)
    let attributes = [NSAttributedString.Key.font: font]
    let attributedString = NSAttributedString(string: title, attributes: attributes)
    let preferredWidth = attributedString.size().width
    let availableWidth = view.bounds.size.width - view.layoutMargins.left - view.layoutMargins.right - 32
    return preferredWidth < availableWidth
  }
}

extension TrackController: EventsViewControllerDataSource, EventsViewControllerDelegate {
  func events(in _: EventsViewController) -> [Event] {
    events
  }

  func eventsViewController(_: EventsViewController, captionFor event: Event) -> String? {
    captions[event]
  }

  func eventsViewController(_: EventsViewController, didSelect event: Event) {
    let eventViewController = makeEventViewController(for: event)
    show(eventViewController, sender: nil)
  }
}

extension TrackController: EventsViewControllerFavoritesDataSource, EventsViewControllerFavoritesDelegate {
  func eventsViewController(_: EventsViewController, canFavorite event: Event) -> Bool {
    !dependencies.favoritesService.contains(event)
  }

  func eventsViewController(_: EventsViewController, didFavorite event: Event) {
    dependencies.favoritesService.addEvent(withIdentifier: event.id)
  }

  func eventsViewController(_: EventsViewController, didUnfavorite event: Event) {
    dependencies.favoritesService.removeEvent(withIdentifier: event.id)
  }

  @objc private func didToggleFavorite() {
    if dependencies.favoritesService.contains(track) {
      dependencies.favoritesService.removeTrack(withIdentifier: track.name)
    } else {
      dependencies.favoritesService.addTrack(withIdentifier: track.name)
    }
  }
}

private extension TrackController {
  func makeEventViewController(for event: Event) -> UIViewController {
    dependencies.navigationService.makeEventViewController(for: event)
  }
}

private extension [Event] {
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
