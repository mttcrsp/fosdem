import Foundation

final class Services {
    let infoService: InfoService
    let liveService = LiveService()
    let yearsService = YearsService()
    let updateService: UpdateService
    let networkService: NetworkService
    let bundleService = BundleService()
    let scheduleService: ScheduleService
    let buildingsService: BuildingsService
    let favoritesService = FavoritesService()
    let persistenceService: PersistenceService

    #if DEBUG
        let debugService = DebugService()
    #endif

    init() throws {
        let preloadService = try PreloadService()
        try preloadService.preloadDatabaseIfNeeded()

        let path = preloadService.databasePath
        persistenceService = try PersistenceService(path: path, migrations: .allMigrations)

        let session = URLSession.shared
        session.configuration.timeoutIntervalForRequest = 30
        session.configuration.timeoutIntervalForResource = 30
        networkService = NetworkService(session: session)

        updateService = UpdateService(networkService: networkService)
        scheduleService = ScheduleService(networkService: networkService, persistenceService: persistenceService)

        infoService = InfoService(bundleService: bundleService)
        buildingsService = BuildingsService(bundleService: bundleService)
    }
}
