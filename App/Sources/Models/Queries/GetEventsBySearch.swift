import Foundation
import GRDB

struct GetEventsBySearch: PersistenceServiceRead {
  let query: String

  func perform(in database: Database) throws -> [Event] {
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
