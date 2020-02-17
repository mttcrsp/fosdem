import Foundation

final class Services {
    let persistenceService: PersistenceService
    let favoritesService: FavoritesService

    init() throws {
        let applicationSupportURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let databaseURL = applicationSupportURL.appendingPathComponent("db.sqlite")
        persistenceService = try PersistenceService(path: databaseURL.path)
        favoritesService = FavoritesService()
    }
}
