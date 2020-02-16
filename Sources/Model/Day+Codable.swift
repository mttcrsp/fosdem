import Foundation

extension Day {
    enum CodingKeys: String, CodingKey {
        case index, date, events = "event", rooms = "room"
    }

    private struct Room: Decodable {
        let event: [Event]
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        index = try container.decode(Int.self, forKey: .index)

        // The format used by the Schedule API changed slightly between 2012 and
        // 2013 when a room entity was introduced.
        let rooms = try container.decode([Room].self, forKey: .rooms)
        let modernEvents = rooms.flatMap { room in room.event }
        let legacyEvents = try container.decode([Event].self, forKey: .events)
        events = modernEvents.isEmpty ? legacyEvents : modernEvents
    }
}
