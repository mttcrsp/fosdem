import UIKit

extension UITableViewRowAction {
    static func favorite(with handler: @escaping (IndexPath) -> Void) -> UITableViewRowAction {
        let title = NSLocalizedString("Favorite", comment: "")
        let action = UITableViewRowAction(style: .normal, title: title) { _, indexPath in handler(indexPath) }
        action.backgroundColor = .systemBlue
        return action
    }

    static func unfavorite(with handler: @escaping (IndexPath) -> Void) -> UITableViewRowAction {
        let title = NSLocalizedString("Unfavorite", comment: "")
        let action = UITableViewRowAction(style: .destructive, title: title) { _, indexPath in handler(indexPath) }
        return action
    }
}
