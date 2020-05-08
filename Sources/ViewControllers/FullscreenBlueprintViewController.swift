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

        if #available(iOS 12.0, *), traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            imageView.image = imageView.image?.inverted
        }
    }

    private func didChangeBlueprint() {
        guard let blueprint = blueprint, let image = UIImage(named: blueprint.imageName) else {
            imageView.image = nil
            return
        }

        if #available(iOS 12.0, *), traitCollection.userInterfaceStyle == .dark {
            imageView.image = image.inverted
        } else {
            imageView.image = image
        }
    }
}
