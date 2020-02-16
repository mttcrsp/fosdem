import Foundation

extension Person {
    enum CodingKeys: String, CodingKey {
        case id, name = "value"
    }
}
