import UIKit

final class FullscreenBlueprintViewController: UIViewController {
    var blueprint: Blueprint? {
        didSet { didChangeBlueprint() }
    }

    private lazy var imageView = ScrollImageView()

    override func loadView() {
        view = imageView
    }

    private func didChangeBlueprint() {
        if let blueprint = blueprint {
            imageView.image = UIImage(named: blueprint.imageName)
        } else {
            imageView.image = nil
        }
    }
}
