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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        var insets = view.layoutMargins
        insets.top += 8
        insets.left += 8
        insets.right += 8
        insets.bottom += 8

        let frame = view.bounds.inset(by: insets)
        imageView.frame = frame
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
