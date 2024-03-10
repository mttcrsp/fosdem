import UIKit

final class FullscreenBlueprintViewController: UIViewController {
  var blueprint: Blueprint? {
    didSet { didChangeBlueprint() }
  }

  private lazy var imageView = ScrollImageView()

  override func loadView() {
    view = imageView
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
      didChangeBlueprint()
    }
  }

  private func didChangeBlueprint() {
    guard let blueprint, let image = UIImage(named: blueprint.imageName) else {
      imageView.image = nil
      return
    }

    if traitCollection.userInterfaceStyle == .dark {
      imageView.image = image.inverted
    } else {
      imageView.image = image
    }
  }
}
