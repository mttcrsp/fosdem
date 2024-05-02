#if DEBUG

import UIKit

final class EventsSlideshowController: UINavigationController {
  typealias Dependencies = HasNavigationService & HasPersistenceService

  enum Mode {
    case all(startingIndex: Int)
    case identifiers(Set<Int>)
  }

  private weak var pageViewController: UIPageViewController?
  private var events: [Event] = []

  private let mode: Mode
  private let dependencies: Dependencies

  init(mode: Mode = .all(startingIndex: 0), dependencies: Dependencies) {
    self.mode = mode
    self.dependencies = dependencies
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    do {
      switch mode {
      case let .identifiers(identifiers):
        let operation = GetEventsByIdentifiers(identifiers: identifiers)
        events = try dependencies.persistenceService.performReadSync(operation)
      case .all:
        let operation = GetAllTracks()
        let tracks = try dependencies.persistenceService.performReadSync(operation)
        events = try tracks.flatMap { track in
          let operation = GetEventsByTrack(track: track.name)
          return try self.dependencies.persistenceService.performReadSync(operation)
        }
      }
    } catch {
      return assertionFailure("Failed to load events: \(error.localizedDescription)")
    }

    guard let eventViewController = makeEventViewController(at: mode.startingIndex) else {
      return assertionFailure("Invalid initial index \(mode.startingIndex) specified")
    }

    let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    pageViewController.setViewControllers([eventViewController], direction: .forward, animated: false)
    pageViewController.dataSource = self
    self.pageViewController = pageViewController
    viewControllers = [pageViewController]

    let nextAction = #selector(arrowRightSelected)
    let nextCommand = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: nextAction)
    addKeyCommand(nextCommand)

    let prevAction = #selector(arrowLeftSelected)
    let prevCommand = UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: prevAction)
    addKeyCommand(prevCommand)

    let showAction = #selector(arrowUp)
    let showCommand = UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: showAction)
    addKeyCommand(showCommand)
  }

  @objc private func arrowRightSelected() {
    guard let pageViewController, let viewController = pageViewController.viewControllers?.first, let afterViewController = self.pageViewController(pageViewController, viewControllerAfter: viewController) else { return }
    pageViewController.setViewControllers([afterViewController], direction: .forward, animated: true)
  }

  @objc private func arrowLeftSelected() {
    guard let pageViewController, let viewController = pageViewController.viewControllers?.first, let beforeViewController = self.pageViewController(pageViewController, viewControllerBefore: viewController) else { return }
    pageViewController.setViewControllers([beforeViewController], direction: .reverse, animated: true)
  }

  @objc private func arrowUp() {
    guard let pageViewController, let index = pageViewController.viewControllers?.first?.fos_index else { return }
    let alertController = UIAlertController(title: nil, message: index.description, preferredStyle: .alert)
    alertController.addAction(.init(title: "Dismiss", style: .cancel))
    present(alertController, animated: true)
  }
}

extension EventsSlideshowController: UIPageViewControllerDataSource {
  func pageViewController(_: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    guard let index = viewController.fos_index, let eventViewController = makeEventViewController(at: index + 1) else { return nil }
    return eventViewController
  }

  func pageViewController(_: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    guard let index = viewController.fos_index, let eventViewController = makeEventViewController(at: index - 1) else { return nil }
    return eventViewController
  }
}

private extension EventsSlideshowController {
  func makeEventViewController(at index: Int) -> UIViewController? {
    guard events.indices ~= index else { return nil }
    let eventViewController = dependencies.navigationService.makeEventViewController(for: events[index])
    eventViewController.fos_index = index
    return eventViewController
  }
}

private extension EventsSlideshowController.Mode {
  var startingIndex: Int {
    switch self {
    case let .all(startingIndex): startingIndex
    case .identifiers: 0
    }
  }
}

private extension UIViewController {
  private static var indexKey = 0

  var fos_index: Int? {
    get { objc_getAssociatedObject(self, &UIViewController.indexKey) as? Int }
    set { objc_setAssociatedObject(self, &UIViewController.indexKey, newValue as Int?, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
  }
}

#endif
