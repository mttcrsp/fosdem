import Foundation

enum AttachmentType: String, Decodable {
    case slides, audio, video, paper, other
}

struct Attachment: Decodable {
    let type: AttachmentType, url: URL, name: String?
}

extension Attachment {
    enum CodingKeys: String, CodingKey {
        case type, url = "href", name = "value"
    }
}
