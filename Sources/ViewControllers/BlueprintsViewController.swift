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

  private lazy var pageControl = UIPageControl()

  private let style: Style

  init(style: Style) {
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

    guard style == .fullscreen else { return }

    pageControl.hidesForSinglePage = true
    pageControl.currentPageIndicatorTintColor = .fos_label
    pageControl.pageIndicatorTintColor = .fos_quaternaryLabel
    pageControl.translatesAutoresizingMaskIntoConstraints = false

    let pageBackgroundView = UIView()
    pageBackgroundView.alpha = 0.8
    pageBackgroundView.layer.cornerRadius = 4
    pageBackgroundView.backgroundColor = .fos_tertiarySystemBackground
    pageBackgroundView.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(pageControl)
    view.insertSubview(pageBackgroundView, belowSubview: pageControl)

    NSLayoutConstraint.activate([
      pageBackgroundView.topAnchor.constraint(equalTo: pageControl.topAnchor),
      pageBackgroundView.bottomAnchor.constraint(equalTo: pageControl.bottomAnchor),
      pageBackgroundView.leadingAnchor.constraint(equalTo: pageControl.leadingAnchor, constant: -12),
      pageBackgroundView.trailingAnchor.constraint(equalTo: pageControl.trailingAnchor, constant: 12),

      pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      pageControl.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor),
    ])
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
    pageControl.numberOfPages = blueprints.count
  }

  private func didChangeVisibleBlueprint() {
    if let blueprintViewController = viewControllers?.first as? BlueprintViewController, let blueprint = blueprintViewController.blueprint {
      title = blueprint.title
    } else if let building = building?.title {
      let format = NSLocalizedString("map.blueprint.title", comment: "")
      let string = String(format: format, building)
      title = string
    }
    pageControl.currentPage = viewControllers?.first?.fos_index ?? 0
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
