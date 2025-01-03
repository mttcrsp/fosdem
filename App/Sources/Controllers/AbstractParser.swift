import libxml2
import UIKit

extension NSAttributedString {
  convenience init?(html: String) {
    guard let node = Parser().parse(html) else { return nil }
    self.init(attributedString: NSMutableAttributedString(node: node))
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
  convenience init(node: ParserNode) {
    if let content = node.content {
      // FIXME: When joining text from multiple lines, browser enginers will
      // inject whitespace if the preceding character requires it. (e.g.
      // `something,\nelse` -> `something, else`) This implementation does not
      // account for that.
      self.init(string: content.replacingOccurrences(of: "\n", with: ""))
      return
    } else if node.name == "br" {
      self.init(string: "\n")
      return
    }

    self.init()

    // Collect attributed strings for all children before attempting to inject
    // whitespace. This way you can know the previous and last characters for
    // nested tags.
    let children: [(node: ParserNode, attributedString: NSAttributedString)] =
      node.children.map { child in (child, NSMutableAttributedString(node: child)) }

    for (index, (child, attributedString)) in children.enumerated() {
      switch child.name {
      case "a", "em", "strong", "code":
        // FIXME: Browser engines are language aware and use language specific
        // rules to determine whether whitespace is necessary or not which are
        // likely more complex than this. This will also not work when there's
        // for links that are nested inside other tags. (e.g. `<b><a>link</a></b>`)
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
      .paragraphStyle: {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        return paragraphStyle
      }()
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

private struct Parser {
  func parse(_ string: String) -> ParserNode? {
    let documentPointer = string.cString(using: .utf8)?.withUnsafeBufferPointer { pointer in
      let options = [HTML_PARSE_RECOVER, HTML_PARSE_NOERROR, HTML_PARSE_NOWARNING].map(\.rawValue).reduce(0, |)
      return htmlReadMemory(pointer.baseAddress, numericCast(pointer.count), nil, nil, Int32(options))
    }

    if let documentPointer {
      defer { xmlFreeDoc(documentPointer) }
      return ParserNode(documentPointer.pointee)
    } else {
      return nil
    }
  }
}

private struct ParserNode {
  var content: String?
  var name: String?
  var children: [ParserNode] = []
  var properties: [String: String] = [:]
}

private extension ParserNode {
  init(_ visitable: Visitable) {
    if let cContent = visitable.content {
      content = String(cString: cContent)
    }

    if let cName = visitable.name {
      name = String(cString: cName)
    }

    if let xmlNode = visitable as? xmlNode {
      var current = visitable.properties
      while let property = current?.pointee {
        if let value = withUnsafePointer(to: xmlNode, { xmlGetProp($0, property.name) }) {
          properties[String(cString: property.name)] = String(cString: value)
        }
        current = property.next
      }
    }

    var current = visitable.children
    while let child = current?.pointee {
      children.append(.init(child))
      current = child.next
    }
  }
}

private protocol Visitable {
  var children: UnsafeMutablePointer<_xmlNode>! { get }
  var last: UnsafeMutablePointer<_xmlNode>! { get }
  var next: UnsafeMutablePointer<_xmlNode>! { get }
  var name: UnsafePointer<xmlChar>! { get }
  var content: UnsafeMutablePointer<xmlChar>! { get }
  var properties: UnsafeMutablePointer<_xmlAttr>! { get }
}

extension _xmlNode: Visitable {}
extension _xmlDoc: Visitable {
  var name: UnsafePointer<xmlChar>! { nil }
  var content: UnsafeMutablePointer<xmlChar>! { nil }
  var properties: UnsafeMutablePointer<_xmlAttr>! { nil }
}
