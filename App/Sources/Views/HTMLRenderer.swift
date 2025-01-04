import UIKit

final class HTMLRenderer {
  func render(_ node: HTMLNode) -> NSAttributedString? {
    NSMutableAttributedString(node: node)
  }
}

private extension NSMutableAttributedString {
  // Interesting test cases from the 2025 schedule:
  // - 4100, multiple links example with `(<a>link</a>)` parentheses nesting
  // - 4159, link right before a parenthesis `<a>link</a>(something)`
  // - 4294, newline right before a punctuation symbol `something,\nelse`
  // - 5452, nested link example `<b><a>link</a></b>` (broken)
  // - 5023, final `<hr />`
  // - 5606, tons of code (both block and inline)
  // - 5850, both ordered and unordered lists
  // - 5933, a weird mix of `<strong>`, `<hr>`, `<li>`, and `<h3>`
  convenience init(node: HTMLNode) {
    if let content = node.content {
      // FIXME: When joining text from multiple lines, browser enginers will
      // inject whitespace if the preceding character requires it. (e.g.
      // `something,\nelse` -> `something, else`) This implementation does not
      // account for that.
      let string = content.replacingOccurrences(of: "\n", with: "")
      let attributes = [NSAttributedString.Key.font: UIFont.fos_preferredFont(forTextStyle: .body)]
      self.init(string: string, attributes: attributes)
      return
    } else if node.name == "br" {
      self.init(string: "\n")
      return
    }

    self.init()

    // Collect attributed strings for all children before attempting to inject
    // whitespace. This way you can know the previous and last characters for
    // nested tags.
    let children: [(node: HTMLNode, attributedString: NSAttributedString)] =
      node.children.map { child in (child, NSMutableAttributedString(node: child)) }

    for (index, (child, attributedString)) in children.enumerated() {
      switch child.name {
      case "a", "em", "strong", "code":
        // FIXME: Browser engines use language specific rules to determine
        // whether whitespace is necessary which are likely more complex than
        // this
        // FIXME: This implementation does not manage correctly nested tags
        // (e.g. `<b><a>link</a></b>`)
        let prevIndex = index - 1
        if children.indices ~= prevIndex {
          let prev = children[prevIndex]
          let prevString = prev.attributedString.string
          if let target = prevString.last, !target.isWhitespace, !target.isParenthesis {
            append(.init(string: " "))
          }
        }

        append(attributedString)

        let nextIndex = index + 1
        if children.indices ~= nextIndex {
          let next = children[nextIndex]
          let nextString = next.attributedString.string
          if let target = nextString.first, !target.isPunctuation || target.isParenthesis {
            append(.init(string: " "))
          }
        }
      case "li":
        let prefix = node.name == "ol" ? "\(index + 1). " : "• "
        append(.init(string: prefix))
        append(attributedString)
        append(.init(string: "\n"))
      case "ul", "ol":
        append(attributedString)
        if index != children.count - 1 {
          append(.init(string: "\n"))
        }
      case "h1", "h2", "h3", "h4", "h5", "h6", "p":
        append(attributedString)
        if index != children.count - 1 {
          append(.init(string: "\n\n"))
        }
      default:
        append(attributedString)
      }
    }

    var attributes: [NSAttributedString.Key: Any] = [
      .foregroundColor: UIColor.label,
      .paragraphStyle: {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        return paragraphStyle
      }(),
    ]

    switch node.name {
    case "a":
      if let href = node.properties["href"] {
        if let url = URL(string: href) {
          attributes[.link] = url
          attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
      }
    case "strong", "h1", "h2", "h3", "h4", "h5", "h6":
      attributes[.font] = UIFont.fos_preferredFont(forTextStyle: .body, withSymbolicTraits: .traitBold)
    case "em":
      attributes[.font] = UIFont.fos_preferredFont(forTextStyle: .body, withSymbolicTraits: .traitItalic)
    case "code":
      attributes[.font] = UIFont.fos_preferredFont(forTextStyle: .body, withSymbolicTraits: .traitMonoSpace)
    default:
      break
    }

    let range = NSRange(location: 0, length: length)
    addAttributes(attributes, range: range)
  }
}

private extension Character {
  private static let parentheses: Set<Character> = ["(", "[", "{", "<"]

  var isParenthesis: Bool {
    Self.parentheses.contains(self)
  }
}
