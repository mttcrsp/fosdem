import UIKit

class BlueprintsEmptyViewController: UIViewController {
    private let label = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(label)
        view.backgroundColor = .fos_systemBackground

        label.textAlignment = .center
        label.textColor = .fos_secondaryLabel
        label.text = NSLocalizedString("map.blueprint.empty", comment: "")
        label.font = .fos_preferredFont(forTextStyle: .body, withSymbolicTraits: .traitItalic)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        label.sizeToFit()
        label.center.x = view.layoutMarginsGuide.layoutFrame.midX
        label.center.y = view.layoutMarginsGuide.layoutFrame.midY
    }
}
