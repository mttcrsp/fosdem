import UIKit

final class VideosController: NSObject {
  typealias Dependencies = HasPlaybackService & HasPersistenceService & HasNavigationService

  var didError: ((UIViewController, Error) -> Void)?

  private weak var videosViewController: UIPageViewController?

  private lazy var watchedViewController: EventsViewController = {
    let watchingViewController = makeEventsViewController()
    watchingViewController.title = L10n.Recent.Video.watching
    watchingViewController.emptyBackgroundTitle = L10n.Recent.Video.Empty.title
    watchingViewController.emptyBackgroundMessage = L10n.Recent.Video.Empty.watching
    return watchingViewController
  }()

  private lazy var watchingViewController: EventsViewController = {
    let watchedViewController = makeEventsViewController()
    watchedViewController.title = L10n.Recent.Video.watched
    watchedViewController.emptyBackgroundTitle = L10n.Recent.Video.Empty.title
    watchedViewController.emptyBackgroundMessage = L10n.Recent.Video.Empty.watched
    return watchedViewController
  }()

  private lazy var segmentedControl: UISegmentedControl = {
    let segmentedAction = #selector(didChangeSegment(_:))
    let segmentedControl = UISegmentedControl()
    segmentedControl.addTarget(self, action: segmentedAction, for: .valueChanged)
    segmentedControl.insertSegment(withTitle: L10n.Recent.Video.watching, at: 0, animated: false)
    segmentedControl.insertSegment(withTitle: L10n.Recent.Video.watched, at: 1, animated: false)
    segmentedControl.selectedSegmentIndex = 0
    return segmentedControl
  }()

  private var watchingEvents: [Event] = []
  private var watchedEvents: [Event] = []
  private var observer: NSObjectProtocol?

  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
    super.init()

    observer = dependencies.playbackService.addObserver { [weak self] in
      self?.reloadData()
    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    if let observer = observer {
      dependencies.playbackService.removeObserver(observer)
    }
  }

  func reloadData() {
    let group = DispatchGroup()
    var groupError: Error?

    let watchedIdentifiers = dependencies.playbackService.watched
    let watchedOperation = EventsForIdentifiers(identifiers: watchedIdentifiers)
    dependencies.persistenceService.performRead(watchedOperation) { [weak self] result in
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

    let watchingIdentifiers = dependencies.playbackService.watching
    let watchingOperation = EventsForIdentifiers(identifiers: watchingIdentifiers)
    dependencies.persistenceService.performRead(watchingOperation) { [weak self] result in
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
      if let self = self, let videosViewController = self.videosViewController, let error = groupError {
        self.didError?(videosViewController, error)
      }
    }
  }

  @objc private func didChangeSegment(_ control: UISegmentedControl) {
    switch control.selectedSegmentIndex {
    case 0:
      let childViewController = watchingViewController
      videosViewController?.setViewControllers([childViewController], direction: .reverse, animated: true)
      videosViewController?.navigationItem.setRightBarButton(childViewController.editButtonItem, animated: true)
    case 1:
      let childViewController = watchedViewController
      videosViewController?.setViewControllers([childViewController], direction: .forward, animated: true)
      videosViewController?.navigationItem.setRightBarButton(childViewController.editButtonItem, animated: true)
    default:
      break
    }
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

  func eventsViewController(_: EventsViewController, captionFor event: Event) -> String? {
    event.formattedPeople
  }

  func eventsViewController(_: EventsViewController, didSelect event: Event) {
    let eventViewController = makeEventViewController(for: event)
    videosViewController?.show(eventViewController, sender: nil)
  }
}

extension VideosController: EventsViewControllerDeleteDelegate {
  func eventsViewController(_: EventsViewController, didDelete event: Event) {
    dependencies.playbackService.setPlaybackPosition(.beginning, forEventWithIdentifier: event.id)
  }
}

extension VideosController: UIPageViewControllerDataSource {
  func pageViewController(_: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    switch viewController {
    case watchingViewController:
      return nil
    case watchedViewController:
      return watchingViewController
    default:
      return nil
    }
  }

  func pageViewController(_: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
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
  func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating _: Bool, previousViewControllers _: [UIViewController], transitionCompleted completed: Bool) {
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

    videosViewController?.navigationItem.setRightBarButton(currentViewController?.editButtonItem, animated: true)
  }
}

extension VideosController {
  func makeVideosViewController() -> UIPageViewController {
    let videosViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    videosViewController.setViewControllers([watchingViewController], direction: .forward, animated: false)
    videosViewController.navigationItem.titleView = segmentedControl
    videosViewController.navigationItem.largeTitleDisplayMode = .never
    videosViewController.view.backgroundColor = .fos_systemBackground
    self.videosViewController = videosViewController
    return videosViewController
  }

  private func makeEventsViewController() -> EventsViewController {
    let eventsViewController = EventsViewController(style: .grouped)
    eventsViewController.navigationItem.largeTitleDisplayMode = .never
    eventsViewController.deleteDelegate = self
    eventsViewController.dataSource = self
    eventsViewController.delegate = self
    return eventsViewController
  }

  private func makeEventViewController(for event: Event) -> UIViewController {
    dependencies.navigationService.makeEventViewController(for: event)
  }
}
