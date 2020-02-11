struct Person: Decodable {
    let id, name: String
}

extension Person {
    enum CodingKeys: String, CodingKey {
        case id, name = "value"
    }
}
