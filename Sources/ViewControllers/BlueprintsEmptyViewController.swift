import UIKit

class BlueprintsEmptyViewController: UIViewController {
    override func loadView() {
        let view = TableBackgroundView()
        view.text = NSLocalizedString("map.blueprint.empty", comment: "")
        self.view = view
    }
}
