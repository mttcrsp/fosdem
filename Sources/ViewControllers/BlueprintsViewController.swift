import UIKit

protocol BlueprintsViewControllerDelegate: AnyObject {
  func blueprintsViewControllerDidTapDismiss(_ blueprintsViewController: BlueprintsViewController)
  func blueprintsViewController(_ blueprintsViewController: BlueprintsViewController, didSelect blueprint: Blueprint)
}

final class BlueprintsViewController: UIPageViewController {
  enum Style {
    case embedded, fullscreen
  }

  weak var blueprintsDelegate: BlueprintsViewControllerDelegate?

  var building: Building? {
    didSet { didChangeBuilding() }
  }

  private lazy var fullscreenButton: UIBarButtonItem = {
    let fullscreenAction = #selector(didTapFullscreen)
    let fullscreenImage = UIImage.fos_systemImage(withName: "arrow.up.left.and.arrow.down.right")
    let fullscreenButton = UIBarButtonItem(image: fullscreenImage, style: .plain, target: self, action: fullscreenAction)
    return fullscreenButton
  }()

  private lazy var fullscreenRecognizer: UITapGestureRecognizer = {
    let fullscreenAction = #selector(didTapFullscreen)
    let fullscreenRecognizer = UITapGestureRecognizer(target: self, action: fullscreenAction)
    return fullscreenRecognizer
  }()

  let style: Style

  init(style: Style) {
    let pageControl = UIPageControl.appearance(whenContainedInInstancesOf: [BlueprintsViewController.self])
    pageControl.pageIndicatorTintColor = .fos_quaternaryLabel
    pageControl.currentPageIndicatorTintColor = .fos_label
    pageControl.hidesForSinglePage = true

    self.style = style
    super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [.interPageSpacing: 20])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private var blueprints: [Blueprint] {
    building?.blueprints ?? []
  }

  private var supportsFullscreenPresentation: Bool {
    style == .embedded && !blueprints.isEmpty
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    delegate = self
    dataSource = self

    view.addGestureRecognizer(fullscreenRecognizer)
    view.backgroundColor = .fos_tertiarySystemBackground

    let dismissAction = #selector(didTapDismiss)
    let dismissImage = UIImage.fos_systemImage(withName: "xmark")
    let dismissButton = UIBarButtonItem(image: dismissImage, style: .plain, target: self, action: dismissAction)
    navigationItem.rightBarButtonItem = dismissButton
  }

  var visibleBlueprint: Blueprint? {
    if let blueprintViewController = viewControllers?.first as? BlueprintViewController {
      return blueprintViewController.blueprint
    } else {
      return nil
    }
  }

  func setVisibleBlueprint(_ blueprint: Blueprint?, animated: Bool) {
    let viewController: UIViewController
    if let blueprint = blueprint, let index = blueprints.firstIndex(of: blueprint) {
      viewController = makeBlueprintViewController(at: index)
    } else {
      assert(blueprint == nil, "Attempting to select blueprint '\(blueprint as Any)' that does not belong to the currently displayed building '\(building as Any)'.")
      viewController = makeEmptyViewController()
    }

    setViewControllers([viewController], direction: .forward, animated: animated)
    didChangeVisibleBlueprint()
  }

  @objc private func didTapDismiss() {
    blueprintsDelegate?.blueprintsViewControllerDidTapDismiss(self)
  }

  @objc private func didTapFullscreen() {
    if let blueprint = visibleBlueprint {
      blueprintsDelegate?.blueprintsViewController(self, didSelect: blueprint)
    }
  }

  private func didChangeBuilding() {
    setVisibleBlueprint(blueprints.first, animated: false)
    fullscreenRecognizer.isEnabled = supportsFullscreenPresentation
    navigationItem.leftBarButtonItem = supportsFullscreenPresentation ? fullscreenButton : nil
  }

  private func didChangeVisibleBlueprint() {
    if let blueprintViewController = viewControllers?.first as? BlueprintViewController, let blueprint = blueprintViewController.blueprint {
      title = blueprint.title
    } else if let building = building?.title {
      let format = NSLocalizedString("map.blueprint.title", comment: "")
      let string = String(format: format, building)
      title = string
    }
  }

  private func makeEmptyViewController() -> BlueprintsEmptyViewController {
    BlueprintsEmptyViewController()
  }

  private func makeBlueprintViewController(at index: Int) -> BlueprintViewController {
    let blueprintViewController = style.blueprintViewControllerClass.init()
    blueprintViewController.blueprint = blueprints[index]
    blueprintViewController.fos_index = index
    return blueprintViewController
  }
}

extension BlueprintsViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    guard let index = viewController.fos_index else { return nil }

    let indexBefore = index - 1
    if blueprints.indices.contains(indexBefore) {
      return makeBlueprintViewController(at: indexBefore)
    } else {
      return nil
    }
  }

  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    guard let index = viewController.fos_index else { return nil }

    let indexAfter = index + 1
    if blueprints.indices.contains(indexAfter) {
      return makeBlueprintViewController(at: indexAfter)
    } else {
      return nil
    }
  }

  func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    didChangeVisibleBlueprint()
  }

  func presentationCount(for pageViewController: UIPageViewController) -> Int {
    switch style {
    case .embedded:
      return 0
    case .fullscreen:
      return blueprints.count
    }
  }

  func presentationIndex(for pageViewController: UIPageViewController) -> Int {
    pageViewController.viewControllers?.first?.fos_index ?? 0
  }
}

private protocol BlueprintViewController: UIViewController {
  var blueprint: Blueprint? { get set }
}

extension EmbeddedBlueprintViewController: BlueprintViewController {}

extension FullscreenBlueprintViewController: BlueprintViewController {}

private extension BlueprintsViewController.Style {
  var blueprintViewControllerClass: BlueprintViewController.Type {
    switch self {
    case .embedded:
      return EmbeddedBlueprintViewController.self
    case .fullscreen:
      return FullscreenBlueprintViewController.self
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
