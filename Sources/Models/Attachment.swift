import Foundation

enum AttachmentType: String, Equatable, Codable {
    case slides, audio, video, paper, other
}

struct Attachment: Equatable, Codable {
    let type: AttachmentType, url: URL, name: String?
}
