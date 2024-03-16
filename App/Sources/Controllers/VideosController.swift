import UIKit

final class VideosController: UIPageViewController {
  typealias Dependencies = HasNavigationService & HasPlaybackService & HasVideosService

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
    if let observer {
      dependencies.playbackService.removeObserver(observer)
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
    navigationItem.backButtonTitle = L10n.Recent.video

    reloadData()
    observer = dependencies.playbackService.addObserver { [weak self] in
      self?.reloadData()
    }
  }

  private func reloadData() {
    dependencies.videosService.loadVideos { [weak self] result in
      guard let self else { return }

      switch result {
      case let .failure(error):
        didError?(self, error)
      case let .success(videos):
        watchedEvents = videos.watched
        watchingEvents = videos.watching
        watchedViewController.reloadData()
        watchingViewController.reloadData()
      }
    }
  }

  @objc private func didChangeSegment(_ control: UISegmentedControl) {
    switch control.selectedSegmentIndex {
    case 0: setViewController(watchingViewController, direction: .reverse, animated: true)
    case 1: setViewController(watchedViewController, direction: .forward, animated: true)
    default: break
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
    case watchingViewController: watchingEvents
    case watchedViewController: watchedEvents
    default: []
    }
  }

  func eventsViewController(_: EventsViewController, captionFor event: Event) -> String? {
    event.formattedPeople
  }

  func eventsViewController(_: EventsViewController, didSelect event: Event) {
    let eventViewController = dependencies.navigationService.makeEventViewController(for: event)
    show(eventViewController, sender: nil)
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
    case watchingViewController: nil
    case watchedViewController: watchingViewController
    default: nil
    }
  }

  func pageViewController(_: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    switch viewController {
    case watchingViewController: watchedViewController
    case watchedViewController: nil
    default: nil
    }
  }
}

extension VideosController: UIPageViewControllerDelegate {
  func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating _: Bool, previousViewControllers _: [UIViewController], transitionCompleted completed: Bool) {
    guard completed else { return }

    let currentViewController = pageViewController.viewControllers?.first
    switch currentViewController {
    case watchingViewController: segmentedControl.selectedSegmentIndex = 0
    case watchedViewController: segmentedControl.selectedSegmentIndex = 1
    default: break
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
}
