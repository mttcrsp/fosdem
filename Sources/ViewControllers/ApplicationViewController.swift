import UIKit

protocol ApplicationViewControllerDelegate: AnyObject {
  func applicationViewControllerDidSelectPrev(_ applicationViewController: ApplicationViewController)
  func applicationViewControllerDidSelectNext(_ applicationViewController: ApplicationViewController)
}

final class ApplicationViewController: UIViewController {
  weak var delegate: ApplicationViewControllerDelegate?

  private let topViewController: UIViewController
  private let bottomViewController: UIViewController?

  init(topViewController: UIViewController, bottomViewController: UIViewController? = nil) {
    self.topViewController = topViewController
    self.bottomViewController = bottomViewController
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func showBottomViewController() {
    bottomViewController?.view.transform = .init(translationX: 0, y: 60)
    topViewController.willMove(toParent: nil)
    UIView.animate(withDuration: 0.2) {
      self.bottomViewController?.view.transform = .identity
      self.topViewController.view.alpha = 0
    } completion: { _ in
      self.topViewController.view.removeFromSuperview()
      self.topViewController.removeFromParent()
    }
  }

  override var canBecomeFirstResponder: Bool {
    true
  }

  override var keyCommands: [UIKeyCommand]? {
    let prevModifierFlags: UIKeyModifierFlags = [.alternate, .shift]
    let nextModifierFlags: UIKeyModifierFlags = [.alternate]
    let prevAction = #selector(didSelectPrevTab)
    let nextAction = #selector(didSelectNextTab)
    let prevCommand = UIKeyCommand(input: "\t", modifierFlags: prevModifierFlags, action: prevAction)
    let nextCommand = UIKeyCommand(input: "\t", modifierFlags: nextModifierFlags, action: nextAction)
    return [prevCommand, nextCommand]
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .fos_systemGroupedBackground

    var constraints: [NSLayoutConstraint] = []
    for viewController in [bottomViewController, topViewController].compactMap({ $0 }) {
      addChild(viewController)
      view.addSubview(viewController.view)
      viewController.view.translatesAutoresizingMaskIntoConstraints = false
      viewController.didMove(toParent: self)

      constraints.append(contentsOf: [
        viewController.view.topAnchor.constraint(equalTo: view.topAnchor),
        viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      ])
    }

    NSLayoutConstraint.activate(constraints)
  }

  @objc private func didSelectPrevTab() {
    delegate?.applicationViewControllerDidSelectPrev(self)
  }

  @objc private func didSelectNextTab() {
    delegate?.applicationViewControllerDidSelectNext(self)
  }
}
