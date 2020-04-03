import Foundation

final class Services {
    let infoService = InfoService()
    let yearsService = YearsService()
    let updateService: UpdateService
    let networkService: NetworkService
    let favoritesService = FavoritesService()
    let persistenceService: PersistenceService
    let acknowledgementsService = AcknowledgementsService()

    #if DEBUG
        let debugService: DebugService
    #endif

    init() throws {
        let path = try FileManager.default.applicationDatabasePath()
        persistenceService = try PersistenceService(path: path, migrations: .allMigrations)

        let session = URLSession.shared
        session.configuration.timeoutIntervalForRequest = 30
        session.configuration.timeoutIntervalForResource = 30
        networkService = NetworkService(session: session)

        updateService = UpdateService(networkService: networkService)

        #if DEBUG
            debugService = DebugService(persistenceService: persistenceService)
        #endif
    }
}

extension FileManager {
    func applicationDatabasePath() throws -> String {
        let applicationSupportURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let applicationDatabaseURL = applicationSupportURL.appendingPathComponent("db.sqlite")
        return applicationDatabaseURL.path
    }
}
