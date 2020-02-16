import Foundation
import GRDB

extension Event: PersistableRecord, FetchableRecord {
    static var databaseTableName: String {
        "events"
    }

    enum Columns: String, ColumnExpression {
        case id, room, track, start, duration, title, subtitle, abstract, summary, people, attachments, links
    }

    init(row: Row) {
        self.init(
            id: row[Columns.id],
            room: row[Columns.room],
            track: row[Columns.track],
            title: row[Columns.title],
            summary: row[Columns.summary],
            subtitle: row[Columns.subtitle],
            abstract: row[Columns.abstract],
            start: row.decode(for: Columns.start.rawValue, default: .init()),
            duration: row.decode(for: Columns.duration.rawValue, default: .init()),
            links: row.decode(for: Columns.links.rawValue, default: .init()),
            people: row.decode(for: Columns.people.rawValue, default: []),
            attachments: row.decode(for: Columns.attachments.rawValue, default: [])
        )
    }

    func encode(to container: inout PersistenceContainer) {
        container[Columns.id.rawValue] = id
        container[Columns.room.rawValue] = room
        container[Columns.track.rawValue] = track
        container[Columns.title.rawValue] = title
        container[Columns.summary.rawValue] = summary
        container[Columns.subtitle.rawValue] = subtitle
        container[Columns.abstract.rawValue] = abstract

        let encoder = JSONEncoder()
        let startData = try? encoder.encode(start)
        let linksData = try? encoder.encode(links)
        let peopleData = try? encoder.encode(links)
        let durationData = try? encoder.encode(duration)
        let attachmentsData = try? encoder.encode(attachments)

        container[Columns.links.rawValue] = linksData?.databaseValue
        container[Columns.start.rawValue] = startData?.databaseValue
        container[Columns.people.rawValue] = peopleData?.databaseValue
        container[Columns.duration.rawValue] = durationData?.databaseValue
        container[Columns.attachments.rawValue] = attachmentsData?.databaseValue
    }
}

private extension Row {
    func decode<Value: Codable>(for column: String, default: Value) -> Value {
        guard let value = self[column] else {
            return `default`
        }

        guard case let .blob(data) = value.databaseValue.storage else {
            return `default`
        }

        guard let decoded = try? JSONDecoder().decode(Value.self, from: data) else {
            return `default`
        }

        return decoded
    }
}
