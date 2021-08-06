import UIKit

final class VideosController: NSObject {
  typealias Dependencies = HasVideosService & HasPlaybackService & HasNavigationService

  var didError: ((UIViewController, Error) -> Void)?

  private weak var videosViewController: UIPageViewController?

  private let watchingTitle = L10n.Recent.Video.watching
  private let watchedTitle = L10n.Recent.Video.watched

  private lazy var watchingViewController: EventsViewController = {
    let watchingViewController = makeEventsViewController()
    watchingViewController.title = watchingTitle
    watchingViewController.emptyBackgroundTitle = L10n.Recent.Video.Empty.title
    watchingViewController.emptyBackgroundMessage = L10n.Recent.Video.Empty.watching
    return watchingViewController
  }()

  private lazy var watchedViewController: EventsViewController = {
    let watchedViewController = makeEventsViewController()
    watchedViewController.title = watchedTitle
    watchedViewController.emptyBackgroundTitle = L10n.Recent.Video.Empty.title
    watchedViewController.emptyBackgroundMessage = L10n.Recent.Video.Empty.watched
    return watchedViewController
  }()

  private lazy var segmentedControl: UISegmentedControl = {
    let segmentedAction = #selector(didChangeSegment(_:))
    let segmentedControl = UISegmentedControl()
    segmentedControl.addTarget(self, action: segmentedAction, for: .valueChanged)
    segmentedControl.insertSegment(withTitle: watchingTitle, at: 0, animated: false)
    segmentedControl.insertSegment(withTitle: watchedTitle, at: 1, animated: false)
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

  private func setViewController(_ childViewController: UIViewController, direction: UIPageViewController.NavigationDirection, animated: Bool) {
    videosViewController?.setViewControllers([childViewController], direction: direction, animated: animated)
    videosViewController?.navigationItem.setRightBarButton(childViewController.editButtonItem, animated: animated)
  }

  func reloadData() {
    dependencies.videosService.loadVideos { [weak self] result in
      guard let self = self, let videosViewController = self.videosViewController else { return }

      switch result {
      case let .failure(error):
        self.didError?(videosViewController, error)
      case let .success(videos):
        self.watchedEvents = videos.watched
        self.watchingEvents = videos.watching
        self.watchedViewController.reloadData()
        self.watchingViewController.reloadData()
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
    self.videosViewController = videosViewController
    videosViewController.navigationItem.largeTitleDisplayMode = .never
    videosViewController.navigationItem.titleView = segmentedControl
    videosViewController.view.backgroundColor = .fos_systemBackground
    videosViewController.dataSource = self
    videosViewController.delegate = self
    setViewController(watchingViewController, direction: .forward, animated: false)
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
