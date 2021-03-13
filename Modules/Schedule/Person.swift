public struct Person: Codable {
  public let id: Int, name: String

  public init(id: Int, name: String) {
    self.id = id
    self.name = name
  }
}

extension Person: Equatable, Hashable {
  public static func == (lhs: Person, rhs: Person) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
