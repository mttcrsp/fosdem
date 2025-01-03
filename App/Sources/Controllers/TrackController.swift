import UIKit

final class TrackController: EventsViewController {
  typealias Dependencies = HasFavoritesService & HasNavigationService & HasPersistenceService

  var didError: ((UIViewController, Error) -> Void)?

  private var favoriteButton: UIBarButtonItem?

  private var captions: [Event: String] = [:]
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
          captions = events.captions
          setEvents(events)
          completion(nil)
        }
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    delegate = self
    favoritesDataSource = self
    favoritesDelegate = self

    let favoriteAction = #selector(didToggleFavorite)
    let favoriteButton = UIBarButtonItem(title: nil, style: .plain, target: self, action: favoriteAction)
    self.favoriteButton = favoriteButton
    navigationItem.rightBarButtonItem = favoriteButton

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
}

extension TrackController: EventsViewControllerDelegate {
  func eventsViewController(_: EventsViewController, captionFor event: Event) -> String? {
    captions[event]
  }

  func eventsViewController(_: EventsViewController, didSelect event: Event) {
    let eventViewController = dependencies.navigationService.makeEventViewController(for: event)
    eventViewController.allowsTrackSelection = false
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
