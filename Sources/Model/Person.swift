import GRDB

struct Person: Codable {
    let id: Int, name: String
}

extension Person: Equatable, Hashable {
    static func == (lhs: Person, rhs: Person) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
