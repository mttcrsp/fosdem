import UIKit

final class EmbeddedBlueprintViewController: UIViewController {
  var blueprint: Blueprint? {
    didSet { didChangeBlueprint() }
  }

  private lazy var imageView = UIImageView()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(imageView)

    imageView.contentMode = .scaleAspectFit
    imageView.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      imageView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 8),
      imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
      imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
      imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
    ])
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
      didChangeBlueprint()
    }
  }

  private func didChangeBlueprint() {
    guard let blueprint = blueprint, let image = UIImage(named: blueprint.imageName) else {
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
