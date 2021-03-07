extension Array where Element == PersistenceServiceMigration {
  static var allMigrations: [PersistenceServiceMigration] {
    [
      CreateTracksTable(),
      CreatePeopleTable(),
      CreateEventsTable(),
      CreateEventsSearchTable(),
      CreateParticipationsTable(),
    ]
  }
}
