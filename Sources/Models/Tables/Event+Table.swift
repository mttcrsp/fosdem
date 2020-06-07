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
    case id, room, track, date, start, duration, title, subtitle, abstract, summary, links, people, attachments
  }

  init(row: Row) {
    let id = row[Columns.id] as Int
    let date = row[Columns.date] as Date
    let room = row[Columns.room] as String
    let track = row[Columns.track] as String
    let title = row[Columns.title] as String
    let summary = row[Columns.summary] as String?
    let subtitle = row[Columns.subtitle] as String?
    let abstract = row[Columns.abstract] as String?

    let start = row.decode(for: Columns.start.rawValue, default: DateComponents())
    let duration = row.decode(for: Columns.duration.rawValue, default: DateComponents())

    let links: [Link] = row.decode(for: Columns.links.rawValue, default: [])
    let people: [Person] = row.decode(for: Columns.people.rawValue, default: [])
    let attachments: [Attachment] = row.decode(for: Columns.attachments.rawValue, default: [])

    self.init(id: id, room: room, track: track, title: title, summary: summary, subtitle: subtitle, abstract: abstract, date: date, start: start, duration: duration, links: links, people: people, attachments: attachments)
  }

  func encode(to container: inout PersistenceContainer) {
    container[Columns.id.rawValue] = id
    container[Columns.date.rawValue] = date
    container[Columns.room.rawValue] = room
    container[Columns.track.rawValue] = track
    container[Columns.title.rawValue] = title
    container[Columns.summary.rawValue] = summary
    container[Columns.subtitle.rawValue] = subtitle
    container[Columns.abstract.rawValue] = abstract

    let encoder = JSONEncoder()
    let startData = try? encoder.encode(start)
    let linksData = try? encoder.encode(links)
    let peopleData = try? encoder.encode(people)
    let durationData = try? encoder.encode(duration)
    let attachmentsData = try? encoder.encode(attachments)

    container[Columns.links.rawValue] = linksData?.databaseValue
    container[Columns.start.rawValue] = startData?.databaseValue
    container[Columns.people.rawValue] = peopleData?.databaseValue
    container[Columns.duration.rawValue] = durationData?.databaseValue
    container[Columns.attachments.rawValue] = attachmentsData?.databaseValue
  }
}

extension Event.Columns {
  static var searchable: [Event.Columns] {
    [.id, .track, .title, .subtitle, .abstract, .summary, .people]
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

    do {
      return try JSONDecoder().decode(Value.self, from: data)
    } catch {
      return `default`
    }
  }
}
