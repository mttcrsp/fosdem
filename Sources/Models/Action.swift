import UIKit

struct Action {
    enum Style {
        case `default`, destructive
    }

    let title: String
    let image: UIImage?
    let style: Style
    let handler: () -> Void

    init(title: String, image: UIImage? = nil, style: Style = .default, handler: @escaping () -> Void = {}) {
        self.title = title
        self.image = image
        self.style = style
        self.handler = handler
    }
}

private extension UITableViewRowAction.Style {
    init(style: Action.Style) {
        switch style {
        case .default:
            self = .default
        case .destructive:
            self = .destructive
        }
    }
}

@available(iOS 11.0, *)
private extension UIContextualAction.Style {
    init(style: Action.Style) {
        switch style {
        case .default:
            self = .normal
        case .destructive:
            self = .destructive
        }
    }
}

@available(iOS 13.0, *)
private extension UIMenuElement.Attributes {
    init(style: Action.Style) {
        switch style {
        case .default:
            self = []
        case .destructive:
            self = [.destructive]
        }
    }
}

private extension UITableViewRowAction {
    convenience init(action: Action) {
        let style = UITableViewRowAction.Style(style: action.style)

        self.init(style: style, title: action.title) { _, _ in
            action.handler()
        }
    }
}

@available(iOS 11.0, *)
private extension UIContextualAction {
    convenience init(action: Action) {
        let style = UIContextualAction.Style(style: action.style)

        self.init(style: style, title: action.title) { _, _, completionHandler in
            action.handler()
            completionHandler(true)
        }

        switch action.style {
        case .default:
            backgroundColor = .systemBlue
        case .destructive:
            break
        }

        image = action.image
    }
}

@available(iOS 13.0, *)
private extension UIAction {
    convenience init(action: Action) {
        let attributes = UIAction.Attributes(style: action.style)

        self.init(title: action.title, image: action.image, attributes: attributes) { _ in
            action.handler()
        }
    }
}

extension Array where Element == UITableViewRowAction {
    init(actions: [Action]) {
        self.init()

        for action in actions {
            append(UITableViewRowAction(action: action))
        }
    }
}

@available(iOS 11.0, *)
extension UISwipeActionsConfiguration {
    convenience init(actions: [Action]) {
        self.init(actions: actions.map(UIContextualAction.init))
    }
}

@available(iOS 13.0, *)
extension UIContextMenuConfiguration {
    convenience init(actions: [Action], previewProvider: UIContextMenuContentPreviewProvider?) {
        let children = actions.map(UIAction.init)

        self.init(
            identifier: nil,
            previewProvider: previewProvider,
            actionProvider: { _ in
                UIMenu(title: "", children: children)
            }
        )
    }
}
