import libxml2

struct HTMLNode {
  var content: String?
  var name: String?
  var children: [HTMLNode] = []
  var properties: [String: String] = [:]
}

struct HTMLParser {
  func parse(_ string: String) -> HTMLNode? {
    let documentPointer = string.cString(using: .utf8)?.withUnsafeBufferPointer { pointer in
      let options = [HTML_PARSE_RECOVER, HTML_PARSE_NOERROR, HTML_PARSE_NOWARNING].map(\.rawValue).reduce(0, |)
      return htmlReadMemory(pointer.baseAddress, numericCast(pointer.count), nil, nil, Int32(options))
    }

    if let documentPointer {
      defer { xmlFreeDoc(documentPointer) }
      return HTMLNode(documentPointer.pointee)
    } else {
      return nil
    }
  }
}

private extension HTMLNode {
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
