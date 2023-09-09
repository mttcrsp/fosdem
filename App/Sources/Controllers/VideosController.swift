import UIKit

final class VideosController: UIPageViewController {
  typealias Dependencies = HasVideosClient & HasPlaybackClient & HasNavigationClient

  var didError: ((VideosController, Error) -> Void)?

  private lazy var watchingViewController = makeEventsViewController()
  private lazy var watchedViewController = makeEventsViewController()
  private lazy var segmentedControl = UISegmentedControl()

  private var watchingEvents: [Event] = []
  private var watchedEvents: [Event] = []
  private var observer: NSObjectProtocol?

  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
    super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    if let observer = observer {
      dependencies.playbackClient.removeObserver(observer)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    delegate = self
    dataSource = self
    view.backgroundColor = .systemBackground

    let watchedTitle = L10n.Recent.Video.watched
    let watchingTitle = L10n.Recent.Video.watching

    watchingViewController.title = watchingTitle
    watchingViewController.emptyBackgroundTitle = L10n.Recent.Video.Empty.title
    watchingViewController.emptyBackgroundMessage = L10n.Recent.Video.Empty.watching

    watchedViewController.title = watchedTitle
    watchedViewController.emptyBackgroundTitle = L10n.Recent.Video.Empty.title
    watchedViewController.emptyBackgroundMessage = L10n.Recent.Video.Empty.watched

    setViewController(watchingViewController, direction: .forward, animated: false)

    let segmentedAction = #selector(didChangeSegment(_:))
    segmentedControl.addTarget(self, action: segmentedAction, for: .valueChanged)
    segmentedControl.insertSegment(withTitle: watchingTitle, at: 0, animated: false)
    segmentedControl.insertSegment(withTitle: watchedTitle, at: 1, animated: false)
    segmentedControl.selectedSegmentIndex = 0
    navigationItem.titleView = segmentedControl
    navigationItem.largeTitleDisplayMode = .never

    reloadData()
    observer = dependencies.playbackClient.addObserver { [weak self] in
      self?.reloadData()
    }
  }

  private func reloadData() {
    dependencies.videosClient.loadVideos { [weak self] result in
      guard let self = self else { return }

      switch result {
      case let .failure(error):
        self.didError?(self, error)
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

  func eventsViewController(_: EventsViewController, captionFor event: Event) -> String? {
    event.formattedPeople
  }

  func eventsViewController(_: EventsViewController, didSelect event: Event) {
    let eventViewController = makeEventViewController(for: event)
    show(eventViewController, sender: nil)
  }
}

extension VideosController: EventsViewControllerDeleteDelegate {
  func eventsViewController(_: EventsViewController, didDelete event: Event) {
    dependencies.playbackClient.setPlaybackPosition(.beginning, event.id)
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

  func makeEventViewController(for event: Event) -> UIViewController {
    dependencies.navigationClient.makeEventViewController(event)
  }
}
