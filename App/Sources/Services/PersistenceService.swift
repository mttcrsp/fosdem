import GRDB

struct PersistenceService {
  var load: (String) throws -> Void
  var allTracks: (@escaping (Result<[Track], Error>) -> Void) -> Void
  var eventsByIdentifier: (Set<Int>, @escaping (Result<[Event], Error>) -> Void) -> Void
  var eventsBySearch: (String, @escaping (Result<[Event], Error>) -> Void) -> Void
  var eventsByTrack: (String, @escaping (Result<[Event], Error>) -> Void) -> Void
  var eventsStartingIn30Minutes: (Date, @escaping (Result<[Event], Error>) -> Void) -> Void
  var upsertSchedule: (Schedule, @escaping (Error?) -> Void) -> Void

  #if DEBUG
  var updateLinksForEvent: (Int, [Link], @escaping (Error?) -> Void) -> Void
  #endif
}

extension PersistenceService {
  init() {
    var database: DatabaseQueue!
    load = { path in
      database = try DatabaseQueue(path: path)

      var migrator = DatabaseMigrator()

      migrator.registerMigration("create people table") { database in
        try database.create(table: Person.databaseTableName) { table in
          table.column(Person.Columns.id.rawValue).primaryKey(onConflict: .replace)
          table.column(Person.Columns.name.rawValue).notNull().indexed()
        }
      }

      migrator.registerMigration("create tracks table") { database in
        try database.create(table: Track.databaseTableName) { table in
          table.column(Track.Columns.name.rawValue).primaryKey(onConflict: .replace)
          table.column(Track.Columns.day.rawValue, .integer)
          table.column(Track.Columns.date.rawValue, .date)
        }
      }

      migrator.registerMigration("create participations table") { database in
        try database.create(table: Participation.databaseTableName) { table in
          table.column(Participation.Columns.personID.rawValue).notNull()
          table.column(Participation.Columns.eventID.rawValue).notNull()
          table.primaryKey([
            Participation.Columns.eventID.rawValue,
            Participation.Columns.personID.rawValue,
          ], onConflict: .replace)
        }
      }

      migrator.registerMigration("create events table") { database in
        try database.create(table: Event.databaseTableName) { table in
          table.column(Event.Columns.id.rawValue).primaryKey(onConflict: .replace)
          table.column(Event.Columns.room.rawValue).notNull().indexed()
          table.column(Event.Columns.track.rawValue).notNull().indexed()
          table.column(Event.Columns.title.rawValue).notNull()
          table.column(Event.Columns.summary.rawValue)
          table.column(Event.Columns.subtitle.rawValue)
          table.column(Event.Columns.abstract.rawValue)
          table.column(Event.Columns.date.rawValue, .datetime)
          table.column(Event.Columns.start.rawValue).notNull()
          table.column(Event.Columns.duration.rawValue).notNull()
          table.column(Event.Columns.links.rawValue, .blob).notNull()
          table.column(Event.Columns.people.rawValue, .blob).notNull()
          table.column(Event.Columns.attachments.rawValue, .blob).notNull()
        }
      }

      migrator.registerMigration("create events search table") { database in
        try database.create(virtualTable: Event.searchDatabaseTableName, using: FTS5()) { table in
          table.synchronize(withTable: Event.databaseTableName)
          table.tokenizer = .porter(wrapping: .ascii())
          for column in Event.Columns.searchable {
            table.column(column.rawValue)
          }
        }
      }

      try migrator.migrate(database)
    }

    func read<Value>(with completion: @escaping (Result<Value, Error>) -> Void, operation: @escaping (Database) throws -> Value) {
      database.asyncRead { result in
        switch result {
        case let .failure(error):
          completion(.failure(error))
        case let .success(database):
          do {
            completion(.success(try operation(database)))
          } catch {
            completion(.failure(error))
          }
        }
      }
    }

    func write(with completion: @escaping (Error?) -> Void, operation: @escaping (Database) throws -> Void) {
      database.asyncWrite(operation) { _, result in
        switch result {
        case .success:
          completion(nil)
        case let .failure(error):
          completion(error)
        }
      }
    }

    allTracks = { completion in
      read(with: completion) { database in
        try Track
          .filter(!Track.Columns.name.like("% stand"))
          .order(Track.Columns.name.lowercased)
          .fetchAll(database)
      }
    }

    eventsByIdentifier = { identifiers, completion in
      read(with: completion) { database in
        try Event.order([Event.Columns.date])
          .filter(identifiers.contains(Event.Columns.id))
          .fetchAll(database)
      }
    }

    eventsBySearch = { query, completion in
      read(with: completion) { database in
        let query = query.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let components = query.components(separatedBy: " ")
        let componentsEscaped = components.map { "\"\($0)\"" }
        let predicate = componentsEscaped.joined(separator: " AND ")
        let predicateWithPrefix = "\(predicate) *"
        let pattern = try database.makeFTS5Pattern(rawPattern: predicateWithPrefix, forTable: Event.searchDatabaseTableName)
        return try Event.fetchAll(database, sql: """
        SELECT events.*
        FROM events JOIN events_search ON events.id = events_search.id
        WHERE events_search MATCH ?
        ORDER BY bm25(events_search, 5.0, 2.0, 5.0, 3.0, 1.0, 1.0, 3.0)
        LIMIT 50
        """, arguments: [pattern])
      }
    }

    eventsByTrack = { track, completion in
      read(with: completion) { database in
        try Event.fetchAll(database, sql: """
        SELECT *
        FROM events
        WHERE track = ?
        ORDER BY date
        """, arguments: [track])
      }
    }

    eventsStartingIn30Minutes = { now, completion in
      read(with: completion) { database in
        let calendar = Calendar.autoupdatingCurrent
        let upperbound = calendar.date(byAdding: .minute, value: 30, to: now)
        let lowerbound = now
        return try Event.fetchAll(database, sql: """
        SELECT *
        FROM events
        WHERE events.date > ? AND events.date < ?
        ORDER BY date
        """, arguments: [lowerbound, upperbound])
      }
    }

    upsertSchedule = { schedule, completion in
      write(with: completion) { database in
        try Event.deleteAll(database)
        try Track.deleteAll(database)
        try Person.deleteAll(database)
        try Participation.deleteAll(database)
        for day in schedule.days {
          for event in day.events {
            try event.insert(database)
            let track = Track(name: event.track, day: day.index, date: day.date)
            try track.insert(database)
            for person in event.people {
              try person.insert(database)
              let participation = Participation(personID: person.id, eventID: event.id)
              try participation.insert(database)
            }
          }
        }
      }
    }

    #if DEBUG
    updateLinksForEvent = { eventID, links, completion in
      write(with: completion) { database in
        let data = try JSONEncoder().encode(links)
        let sql = "UPDATE events SET links = ?, summary = 'testing' WHERE id = ?"
        try database.execute(sql: sql, arguments: [data, eventID])
      }
    }
    #endif
  }

  static let liveValue = Self()
}

extension Event: PersistableRecord, FetchableRecord {
  static let databaseTableName = "events"
  static let searchDatabaseTableName = "\(databaseTableName)_search"

  enum Columns: String, CaseIterable, ColumnExpression {
    case id
    case room
    case track
    case date
    case start
    case duration
    case title
    case subtitle
    case abstract
    case summary
    case links
    case people
    case attachments
  }

  init(row: Row) {
    self.init(
      id: row[Columns.id] as Int,
      room: row[Columns.room] as String,
      track: row[Columns.track] as String,
      title: row[Columns.title] as String,
      summary: row[Columns.summary] as String?,
      subtitle: row[Columns.subtitle] as String?,
      abstract: row[Columns.abstract] as String?,
      date: row[Columns.date] as Date,
      start: row.decode(for: Columns.start.rawValue, default: DateComponents()),
      duration: row.decode(for: Columns.duration.rawValue, default: DateComponents()),
      links: row.decode(for: Columns.links.rawValue, default: []),
      people: row.decode(for: Columns.people.rawValue, default: []),
      attachments: row.decode(for: Columns.attachments.rawValue, default: [])
    )
  }

  func encode(to container: inout PersistenceContainer) {
    let encoder = JSONEncoder()
    let startData = try? encoder.encode(start)
    let linksData = try? encoder.encode(links)
    let peopleData = try? encoder.encode(people)
    let durationData = try? encoder.encode(duration)
    let attachmentsData = try? encoder.encode(attachments)
    container[Columns.id.rawValue] = id
    container[Columns.date.rawValue] = date
    container[Columns.room.rawValue] = room
    container[Columns.track.rawValue] = track
    container[Columns.title.rawValue] = title
    container[Columns.summary.rawValue] = summary
    container[Columns.subtitle.rawValue] = subtitle
    container[Columns.abstract.rawValue] = abstract
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

extension Participation: PersistableRecord, FetchableRecord {
  static let databaseTableName = "participations"

  enum Columns: String, ColumnExpression {
    case personID, eventID
  }
}

extension Person: PersistableRecord, FetchableRecord {
  static let databaseTableName = "people"

  enum Columns: String, ColumnExpression {
    case id, name
  }

  init(row: Row) {
    self.init(id: row[Columns.id], name: row[Columns.name])
  }

  func encode(to container: inout PersistenceContainer) {
    container[Columns.id.rawValue] = id
    container[Columns.name.rawValue] = name
  }
}

extension Track: PersistableRecord, FetchableRecord {
  static let databaseTableName = "tracks"

  enum Columns: String, ColumnExpression {
    case name, day, date
  }

  init(row: Row) {
    self.init(
      name: row[Columns.name],
      day: row[Columns.day],
      date: row[Columns.date]
    )
  }

  func encode(to container: inout PersistenceContainer) {
    container[Columns.day.rawValue] = day
    container[Columns.name.rawValue] = name
    container[Columns.date.rawValue] = date
  }
}

/// @mockable
protocol PersistenceServiceProtocol {
  var load: (String) throws -> Void { get }
  var allTracks: (@escaping (Result<[Track], Error>) -> Void) -> Void { get }
  var eventsByIdentifier: (Set<Int>, @escaping (Result<[Event], Error>) -> Void) -> Void { get }
  var eventsBySearch: (String, @escaping (Result<[Event], Error>) -> Void) -> Void { get }
  var eventsByTrack: (String, @escaping (Result<[Event], Error>) -> Void) -> Void { get }
  var eventsStartingIn30Minutes: (Date, @escaping (Result<[Event], Error>) -> Void) -> Void { get }
  var upsertSchedule: (Schedule, @escaping (Error?) -> Void) -> Void { get }

  #if DEBUG
  var updateLinksForEvent: (Int, [Link], @escaping (Error?) -> Void) -> Void { get }
  #endif
}

extension PersistenceService: PersistenceServiceProtocol {}

protocol HasPersistenceService {
  var persistenceService: PersistenceServiceProtocol { get }
}
