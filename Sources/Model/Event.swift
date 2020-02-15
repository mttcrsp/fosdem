import Foundation

struct Event {
    let id: String
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

extension Event: Hashable, Equatable {
    static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Event {
    var formattedStart: String? {
        DateComponentsFormatter.time.string(from: start)
    }

    var video: Link? {
        links.first { link in link.url?.pathExtension == "mp4" }
    }
}

extension Event: Decodable {
    enum CodingKeys: String, CodingKey {
        case id, room, track, start, duration
        case title, subtitle, abstract, summary
        case people = "persons", attachments, links
    }

    private struct Links: Decodable { let link: [Link] }
    private struct Persons: Decodable { let person: [Person] }
    private struct Attachments: Decodable { let attachment: [Attachment] }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        room = try container.decode(String.self, forKey: .room)
        track = try container.decode(String.self, forKey: .track)
        title = try container.decode(String.self, forKey: .title)

        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        abstract = try container.decodeIfPresent(String.self, forKey: .abstract)
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)

        let start = try container.decode(String.self, forKey: .start)
        let startComponents = start.components(separatedBy: ":")
        guard startComponents.count == 2, let startHH = Int(startComponents[0]), let startMM = Int(startComponents[1]) else {
            throw DecodingError.dataCorruptedError(forKey: .start, in: container, debugDescription: "Unexpected start time format different from HH:mm")
        }

        let duration = try container.decode(String.self, forKey: .duration)
        let durationComponents = duration.components(separatedBy: ":")
        guard durationComponents.count == 2, let durationHH = Int(durationComponents[0]), let durationMM = Int(durationComponents[1]) else {
            throw DecodingError.dataCorruptedError(forKey: .duration, in: container, debugDescription: "Unexpected duration format different from HH:mm")
        }

        self.start = DateComponents(hour: startHH, minute: startMM)
        self.duration = DateComponents(hour: durationHH, minute: durationMM)

        links = try container.decodeIfPresent(Links.self, forKey: .links)?.link ?? []
        people = try container.decodeIfPresent(Persons.self, forKey: .people)?.person ?? []
        attachments = try container.decodeIfPresent(Attachments.self, forKey: .attachments)?.attachment ?? []
    }
}
