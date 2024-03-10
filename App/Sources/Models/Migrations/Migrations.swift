extension [PersistenceServiceMigration] {
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
