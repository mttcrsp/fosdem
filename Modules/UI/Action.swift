import UIKit

public struct Action {
  public enum Style {
    case `default`, destructive
  }

  public let title: String
  public let image: UIImage?
  public let style: Style
  public let handler: () -> Void

  public init(title: String, image: UIImage? = nil, style: Style = .default, handler: @escaping () -> Void = {}) {
    self.title = title
    self.image = image
    self.style = style
    self.handler = handler
  }
}

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

public extension UISwipeActionsConfiguration {
  convenience init?(actions: [Action]) {
    guard !actions.isEmpty else { return nil }
    self.init(actions: actions.map(UIContextualAction.init))
  }
}

@available(iOS 13.0, *)
public extension UIContextMenuConfiguration {
  convenience init?(actions: [Action]) {
    guard !actions.isEmpty else { return nil }

    let children = actions.map(UIAction.init)

    self.init(
      identifier: nil,
      previewProvider: nil,
      actionProvider: { _ in
        UIMenu(title: "", children: children)
      }
    )
  }
}
