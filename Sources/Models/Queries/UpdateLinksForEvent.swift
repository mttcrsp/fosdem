#if DEBUG
import Foundation
import GRDB

struct UpdateLinksForEvent: PersistenceServiceWrite {
  let eventID: Int
  let links: [Link]

  func perform(in database: Database) throws {
    let data = try JSONEncoder().encode(links)
    let sql = "UPDATE events SET links = ?, summary = 'testing' WHERE id = ?"
    try database.execute(sql: sql, arguments: [data, eventID])
  }
}
#endif
