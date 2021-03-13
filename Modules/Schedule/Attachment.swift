import Foundation

public enum AttachmentType: String, Equatable, Codable {
  case slides, audio, video, paper, other
}

public struct Attachment: Equatable, Codable {
  public let type: AttachmentType, url: URL, name: String?
}
