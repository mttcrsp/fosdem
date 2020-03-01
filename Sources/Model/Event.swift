import Foundation
import GRDB

struct Event: Codable {
    let id: Int
    let room: String
    let track: String

    let title: String
    let summary: String?
    let subtitle: String?
    let abstract: String?

    let start: DateComponents
    let duration: DateComponents

    let links: [Link]
    let people: [Person]
    let attachments: [Attachment]
}

extension Event {
    var formattedStart: String? {
        DateComponentsFormatter.time.string(from: start)
    }

    var video: Link? {
        links.first { link in link.url?.pathExtension == "mp4" }
    }
}

extension Event: Hashable, Equatable {
    static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
