import UIKit

protocol VideosControllerDelegate: AnyObject {
  func videosController(_ videosController: VideosController, didError error: Error)
}

final class VideosController: UIPageViewController {
  weak var videoDelegate: VideosControllerDelegate?

  private lazy var watchingViewController = makeEventsViewController()
  private lazy var watchedViewController = makeEventsViewController()
  private lazy var segmentedControl = UISegmentedControl()

  private var watchingEvents: [Event] = []
  private var watchedEvents: [Event] = []
  private var observer: NSObjectProtocol?

  private let services: Services

  init(services: Services) {
    self.services = services
    super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    if let observer = observer {
      services.playbackService.removeObserver(observer)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    delegate = self
    dataSource = self
    view.backgroundColor = .fos_systemBackground

    let watchedTitle = NSLocalizedString("recent.video.watched", comment: "")
    let watchingTitle = NSLocalizedString("recent.video.watching", comment: "")

    watchingViewController.title = watchingTitle
    watchingViewController.emptyBackgroundTitle = FOSLocalizedString("recent.video.empty.title")
    watchingViewController.emptyBackgroundMessage = FOSLocalizedString("recent.video.empty.watching")

    watchedViewController.title = watchedTitle
    watchedViewController.emptyBackgroundTitle = FOSLocalizedString("recent.video.empty.title")
    watchedViewController.emptyBackgroundMessage = FOSLocalizedString("recent.video.empty.watched")

    setViewController(watchingViewController, direction: .forward, animated: false)

    let segmentedAction = #selector(didChangeSegment(_:))
    segmentedControl.addTarget(self, action: segmentedAction, for: .valueChanged)
    segmentedControl.insertSegment(withTitle: watchingTitle, at: 0, animated: false)
    segmentedControl.insertSegment(withTitle: watchedTitle, at: 1, animated: false)
    segmentedControl.selectedSegmentIndex = 0
    navigationItem.titleView = segmentedControl
    navigationItem.largeTitleDisplayMode = .never

    reloadData()
    observer = services.playbackService.addObserver { [weak self] in
      self?.reloadData()
    }
  }

  private func reloadData() {
    let group = DispatchGroup()
    var groupError: Error?

    let watchedIdentifiers = services.playbackService.watched
    let watchedOperation = EventsForIdentifiers(identifiers: watchedIdentifiers)
    services.persistenceService.performRead(watchedOperation) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case let .failure(error):
          groupError = groupError ?? error
        case let .success(events):
          self?.watchedEvents = events
          self?.watchedViewController.reloadData()
        }
        group.leave()
      }
    }
    group.enter()

    let watchingIdentifiers = services.playbackService.watching
    let watchingOperation = EventsForIdentifiers(identifiers: watchingIdentifiers)
    services.persistenceService.performRead(watchingOperation) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case let .failure(error):
          groupError = groupError ?? error
        case let .success(events):
          self?.watchingEvents = events
          self?.watchingViewController.reloadData()
        }
        group.leave()
      }
    }
    group.enter()

    group.notify(queue: .main) { [weak self] in
      if let self = self, let error = groupError {
        self.videoDelegate?.videosController(self, didError: error)
      }
    }
  }

  @objc private func didChangeSegment(_ control: UISegmentedControl) {
    switch control.selectedSegmentIndex {
    case 0:
      setViewController(watchingViewController, direction: .reverse, animated: true)
    case 1:
      setViewController(watchedViewController, direction: .forward, animated: true)
    default:
      break
    }
  }

  private func setViewController(_ childViewController: UIViewController, direction: UIPageViewController.NavigationDirection, animated: Bool) {
    setViewControllers([childViewController], direction: direction, animated: animated)
    navigationItem.setRightBarButton(childViewController.editButtonItem, animated: animated)
  }
}

extension VideosController: EventsViewControllerDataSource, EventsViewControllerDelegate {
  func events(in eventsViewController: EventsViewController) -> [Event] {
    switch eventsViewController {
    case watchingViewController:
      return watchingEvents
    case watchedViewController:
      return watchedEvents
    default:
      return []
    }
  }

  func eventsViewController(_ eventsViewController: EventsViewController, captionFor event: Event) -> String? {
    event.formattedPeople
  }

  func eventsViewController(_ eventsViewController: EventsViewController, didSelect event: Event) {
    let eventViewController = makeEventViewController(for: event)
    show(eventViewController, sender: nil)
  }
}

extension VideosController: EventsViewControllerDeleteDelegate {
  func eventsViewController(_ eventsViewController: EventsViewController, canDelete event: Event) -> Bool {
    true
  }

  func eventsViewController(_ eventsViewController: EventsViewController, didDelete event: Event) {
    services.playbackService.setPlaybackPosition(.beginning, forEventWithIdentifier: event.id)
  }
}

extension VideosController: UIPageViewControllerDataSource {
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    switch viewController {
    case watchingViewController:
      return nil
    case watchedViewController:
      return watchingViewController
    default:
      return nil
    }
  }

  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    switch viewController {
    case watchingViewController:
      return watchedViewController
    case watchedViewController:
      return nil
    default:
      return nil
    }
  }
}

extension VideosController: UIPageViewControllerDelegate {
  func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    guard completed else { return }

    let currentViewController = pageViewController.viewControllers?.first

    switch currentViewController {
    case watchingViewController:
      segmentedControl.selectedSegmentIndex = 0
    case watchedViewController:
      segmentedControl.selectedSegmentIndex = 1
    default:
      break
    }

    navigationItem.setRightBarButton(currentViewController?.editButtonItem, animated: true)
  }
}

private extension VideosController {
  func makeEventsViewController() -> EventsViewController {
    let eventsViewController = EventsViewController(style: .grouped)
    eventsViewController.navigationItem.largeTitleDisplayMode = .never
    eventsViewController.deleteDelegate = self
    eventsViewController.dataSource = self
    eventsViewController.delegate = self
    return eventsViewController
  }

  func makeEventViewController(for event: Event) -> EventController {
    EventController(event: event, services: services)
  }
}
