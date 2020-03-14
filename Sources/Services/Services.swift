import Foundation

final class Services {
    let favoritesService = FavoritesService()
    let persistenceService: PersistenceService
    let acknowledgementsService = AcknowledgementsService()

    init() throws {
        let applicationSupportURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let applicationDatabaseURL = applicationSupportURL.appendingPathComponent("db.sqlite")
        let path = applicationDatabaseURL.path

        var migrations: [PersistenceServiceMigration] = []
        migrations.append(CreateTracksTable())
        migrations.append(CreatePeopleTable())
        migrations.append(CreateEventsTable())
        migrations.append(CreateEventsSearchTable())
        migrations.append(CreateParticipationsTable())

        persistenceService = try PersistenceService(path: path, migrations: migrations)
    }
}
