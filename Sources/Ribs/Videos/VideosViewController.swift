import RIBs
import UIKit

protocol VideosPresentableListener: AnyObject {
  func delete(_ event: Event)
  func select(_ event: Event)
  func deselectEvent()
}

final class VideosViewController: UINavigationController {
  weak var listener: VideosPresentableListener?

  var watchedEvents: [Event] = [] {
    didSet { watchedViewController.reloadData() }
  }

  var watchingEvents: [Event] = [] {
    didSet { watchingViewController.reloadData() }
  }

  private weak var eventViewController: UIViewController?
  private weak var pageViewController: UIPageViewController?
  private lazy var watchedViewController = makeEventsViewController()
  private lazy var watchingViewController = makeEventsViewController()

  private lazy var segmentedControl = UISegmentedControl()

  init() {
    let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    self.pageViewController = pageViewController
    super.init(rootViewController: pageViewController)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension VideosViewController {
  override func viewDidLoad() {
    super.viewDidLoad()

    delegate = self

    let watchedTitle = L10n.Recent.Video.watched
    let watchingTitle = L10n.Recent.Video.watching

    watchingViewController.title = watchingTitle
    watchingViewController.emptyBackgroundTitle = L10n.Recent.Video.Empty.title
    watchingViewController.emptyBackgroundMessage = L10n.Recent.Video.Empty.watching

    watchedViewController.title = watchedTitle
    watchedViewController.emptyBackgroundTitle = L10n.Recent.Video.Empty.title
    watchedViewController.emptyBackgroundMessage = L10n.Recent.Video.Empty.watched

    let segmentedAction = #selector(didChangeSegment(_:))
    segmentedControl.addTarget(self, action: segmentedAction, for: .valueChanged)
    segmentedControl.insertSegment(withTitle: watchingTitle, at: 0, animated: false)
    segmentedControl.insertSegment(withTitle: watchedTitle, at: 1, animated: false)
    segmentedControl.selectedSegmentIndex = 0

    pageViewController?.delegate = self
    pageViewController?.dataSource = self
    pageViewController?.navigationItem.titleView = segmentedControl
    pageViewController?.navigationItem.largeTitleDisplayMode = .never
    pageViewController?.view.backgroundColor = .fos_systemBackground

    setViewController(watchingViewController, direction: .forward, animated: false)
  }
}

extension VideosViewController: VideosPresentable {}

extension VideosViewController: VideosViewControllable {
  func showEvent(_ eventViewControllable: ViewControllable) {
    let eventViewController = eventViewControllable.uiviewController
    self.eventViewController = eventViewController
    show(eventViewController, sender: nil)
  }
}

extension VideosViewController: EventsViewControllerDataSource {
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
}

extension VideosViewController: EventsViewControllerDelegate {
  func eventsViewController(_: EventsViewController, didSelect event: Event) {
    listener?.select(event)
  }
}

extension VideosViewController: EventsViewControllerDeleteDelegate {
  func eventsViewController(_: EventsViewController, didDelete event: Event) {
    listener?.delete(event)
  }
}

extension VideosViewController: UIPageViewControllerDataSource {
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

extension VideosViewController: UIPageViewControllerDelegate {
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

    pageViewController.navigationItem.setRightBarButton(currentViewController?.editButtonItem, animated: true)
  }
}

extension VideosViewController: UINavigationControllerDelegate {
  func navigationController(_: UINavigationController, didShow viewController: UIViewController, animated _: Bool) {
    if !viewControllers.contains(where: { viewController in viewController == eventViewController }) {
      listener?.deselectEvent()
    }
  }
}

private extension VideosViewController {
  @objc func didChangeSegment(_ control: UISegmentedControl) {
    switch control.selectedSegmentIndex {
    case 0:
      setViewController(watchingViewController, direction: .reverse, animated: true)
    case 1:
      setViewController(watchedViewController, direction: .forward, animated: true)
    default:
      break
    }
  }

  func setViewController(_ childViewController: UIViewController, direction: UIPageViewController.NavigationDirection, animated: Bool) {
    pageViewController?.setViewControllers([childViewController], direction: direction, animated: animated)
    pageViewController?.navigationItem.setRightBarButton(childViewController.editButtonItem, animated: animated)
  }

  func makeEventsViewController() -> EventsViewController {
    let eventsViewController = EventsViewController(style: .grouped)
    eventsViewController.navigationItem.largeTitleDisplayMode = .never
    eventsViewController.deleteDelegate = self
    eventsViewController.dataSource = self
    eventsViewController.delegate = self
    return eventsViewController
  }
}
