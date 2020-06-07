extension Array where Element == PersistenceServiceMigration {
  static var allMigrations: [PersistenceServiceMigration] {
    var migrations: [PersistenceServiceMigration] = []
    migrations.append(CreateTracksTable())
    migrations.append(CreatePeopleTable())
    migrations.append(CreateEventsTable())
    migrations.append(CreateEventsSearchTable())
    migrations.append(CreateParticipationsTable())
    return migrations
  }
}
