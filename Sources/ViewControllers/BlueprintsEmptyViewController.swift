import L10n
import UIKit

class BlueprintsEmptyViewController: UIViewController {
  private let label = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()

    view.addSubview(label)
    view.backgroundColor = .fos_tertiarySystemBackground

    label.textAlignment = .center
    label.textColor = .fos_secondaryLabel
    label.accessibilityIdentifier = "empty_blueprints"
    label.text = L10n.Map.Blueprint.empty
    label.font = .fos_preferredFont(forTextStyle: .body, withSymbolicTraits: .traitItalic)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    label.sizeToFit()
    label.center.x = view.layoutMarginsGuide.layoutFrame.midX
    label.center.y = view.layoutMarginsGuide.layoutFrame.midY
  }
}
