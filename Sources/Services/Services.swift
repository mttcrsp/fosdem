import Foundation

final class Services {
    let infoService: InfoService
    let liveService = LiveService()
    let crashService: CrashService?
    let updateService: UpdateService
    let tracksService: TracksService
    let yearsService = YearsService()
    let networkService: NetworkService
    let bundleService = BundleService()
    let scheduleService: ScheduleService
    let buildingsService: BuildingsService
    let locationService = LocationService()
    let favoritesService = FavoritesService()
    let persistenceService: PersistenceService
    let acknowledgementsService = AcknowledgementsService()

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

        #if DEBUG
            crashService = nil
        #else
            crashService = CrashService(networkService: networkService)
        #endif

        updateService = UpdateService(networkService: networkService)
        tracksService = TracksService(favoritesService: favoritesService, persistenceService: persistenceService)
        scheduleService = ScheduleService(networkService: networkService, persistenceService: persistenceService)

        infoService = InfoService(bundleService: bundleService)
        buildingsService = BuildingsService(bundleService: bundleService)
    }
}
