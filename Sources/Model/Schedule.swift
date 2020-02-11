struct Schedule: Decodable {
    let conference: Conference, days: [Day]
}

extension Schedule {
    enum CodingKeys: String, CodingKey {
        case conference, days = "day"
    }
}
