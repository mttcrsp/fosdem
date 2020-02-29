import Foundation

final class Services {
    let acknowledgementsService: AcknowledgementsService
    let persistenceService: PersistenceService
    let favoritesService: FavoritesService
    let activityService: ActivityService

    init() throws {
        let applicationSupportURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let databaseURL = applicationSupportURL.appendingPathComponent("db.sqlite")
        persistenceService = try PersistenceService(path: databaseURL.path)
        acknowledgementsService = AcknowledgementsService()
        favoritesService = FavoritesService()
        activityService = ActivityService()
    }
}
