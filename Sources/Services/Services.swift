import Foundation

final class Services {
    let infoService = InfoService()
    let yearsService = YearsService()
    let favoritesService = FavoritesService()
    let persistenceService: PersistenceService
    let acknowledgementsService = AcknowledgementsService()

    init() throws {
        let path = try FileManager.default.applicationDatabasePath()
        persistenceService = try PersistenceService(path: path, migrations: .allMigrations)
    }
}

extension FileManager {
    func applicationDatabasePath() throws -> String {
        let applicationSupportURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let applicationDatabaseURL = applicationSupportURL.appendingPathComponent("db.sqlite")
        return applicationDatabaseURL.path
    }
}
