struct Person: Decodable {
    let id, name: String
}

extension Person: Hashable, Equatable {
    static func == (lhs: Person, rhs: Person) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Person {
    enum CodingKeys: String, CodingKey {
        case id, name = "value"
    }
}
