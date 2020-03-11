import Foundation
import GRDB

extension Event: PersistableRecord, FetchableRecord {
    static var databaseTableName: String {
        "events"
    }

    static var searchDatabaseTableName: String {
        "\(databaseTableName)_search"
    }

    enum Columns: String, CaseIterable, ColumnExpression {
        case id, room, track, start, duration, title, subtitle, abstract, summary, people, attachments, links
    }

    static func createTable(in database: GRDB.Database) throws {
        try database.create(table: Event.databaseTableName) { table in
            table.column(Event.Columns.id.rawValue).primaryKey(onConflict: .replace)
            table.column(Event.Columns.room.rawValue).notNull().indexed()
            table.column(Event.Columns.track.rawValue).notNull().indexed()

            table.column(Event.Columns.title.rawValue).notNull()
            table.column(Event.Columns.summary.rawValue)
            table.column(Event.Columns.subtitle.rawValue)
            table.column(Event.Columns.abstract.rawValue)

            table.column(Event.Columns.start.rawValue).notNull()
            table.column(Event.Columns.duration.rawValue).notNull()

            table.column(Event.Columns.links.rawValue, .blob).notNull()
            table.column(Event.Columns.people.rawValue, .blob).notNull()
            table.column(Event.Columns.attachments.rawValue, .blob).notNull()
        }
    }

    static func createSearchTable(in database: GRDB.Database) throws {
        try database.create(virtualTable: Event.searchDatabaseTableName, using: FTS4()) { table in
            table.synchronize(withTable: Event.databaseTableName)
            table.tokenizer = .unicode61()

            for column in Event.Columns.allCases {
                table.column(column.rawValue)
            }
        }
    }

    init(row: Row) {
        let id = row[Columns.id] as Int
        let room = row[Columns.room] as String
        let track = row[Columns.track] as String
        let title = row[Columns.title] as String
        let summary = row[Columns.summary] as String?
        let subtitle = row[Columns.subtitle] as String?
        let abstract = row[Columns.abstract] as String?

        let start = row.decode(for: Columns.start.rawValue, default: DateComponents())
        let duration = row.decode(for: Columns.duration.rawValue, default: DateComponents())

        let links = row.decode(for: Columns.links.rawValue, default: [] as [Link])
        let people = row.decode(for: Columns.people.rawValue, default: [] as [Person])
        let attachments = row.decode(for: Columns.attachments.rawValue, default: [] as [Attachment])

        self.init(id: id, room: room, track: track, title: title, summary: summary, subtitle: subtitle, abstract: abstract, start: start, duration: duration, links: links, people: people, attachments: attachments)
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
