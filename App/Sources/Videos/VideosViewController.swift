import Combine
import UIKit

final class VideosViewController: UIPageViewController {
  typealias Dependencies = HasNavigationService

  var didError: ((VideosViewController, Error) -> Void)?
  private var cancellables: [AnyCancellable] = []
  private lazy var watchingViewController = makeEventsViewController()
  private lazy var watchedViewController = makeEventsViewController()
  private lazy var segmentedControl = UISegmentedControl()
  private let dependencies: Dependencies
  private let viewModel: VideosViewModel

  init(dependencies: Dependencies, viewModel: VideosViewModel) {
    self.dependencies = dependencies
    self.viewModel = viewModel
    super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    viewModel.didUnload()
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

    viewModel.$watchedEvents
      .scan(([], [])) { ($0.1, $1) }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] oldEvents, newEvents in
        self?.watchedViewController.updateEvents(from: oldEvents, to: newEvents)
      }
      .store(in: &cancellables)

    func update(_: EventsViewController, from _: [Event], to _: [Event]) {}

    viewModel.$watchingEvents
      .scan(([], [])) { ($0.1, $1) }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] oldEvents, newEvents in
        self?.watchingViewController.updateEvents(from: oldEvents, to: newEvents)
      }
      .store(in: &cancellables)

    viewModel.didFail
      .receive(on: DispatchQueue.main)
      .sink { [weak self] error in
        guard let self else { return }
        didError?(self, error)
      }
      .store(in: &cancellables)

    viewModel.didLoad()
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

extension VideosViewController: EventsViewControllerDataSource, EventsViewControllerDelegate {
  func events(in eventsViewController: EventsViewController) -> [Event] {
    switch eventsViewController {
    case watchingViewController: viewModel.watchingEvents
    case watchedViewController: viewModel.watchedEvents
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

extension VideosViewController: EventsViewControllerDeleteDelegate {
  func eventsViewController(_: EventsViewController, didDelete event: Event) {
    viewModel.didDelete(event)
  }
}

extension VideosViewController: UIPageViewControllerDataSource {
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

extension VideosViewController: UIPageViewControllerDelegate {
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

private extension VideosViewController {
  func makeEventsViewController() -> EventsViewController {
    let eventsViewController = EventsViewController(style: .grouped)
    eventsViewController.navigationItem.largeTitleDisplayMode = .never
    eventsViewController.deleteDelegate = self
    eventsViewController.dataSource = self
    eventsViewController.delegate = self
    return eventsViewController
  }
}

private extension EventsViewController {
  func updateEvents(from oldEvents: [Event], to newEvents: [Event]) {
    guard isViewLoaded else { return }

    if view.window == nil {
      reloadData()
    } else {
      beginUpdates()
      for difference in newEvents.difference(from: oldEvents) {
        switch difference {
        case let .insert(index, _, _): insertEvent(at: index)
        case let .remove(index, _, _): deleteEvent(at: index)
        }
      }
      endUpdates()
    }
  }
}
