import Foundation

extension Attachment {
    enum CodingKeys: String, CodingKey {
        case type, url = "href", name = "value"
    }
}
