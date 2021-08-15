import Foundation

class Services {
  let launchService: LaunchServiceProtocol

  let bundleService = BundleService()
  let playbackService: PlaybackServiceProtocol = PlaybackService()
  let favoritesService: FavoritesServiceProtocol = FavoritesService()
  let acknowledgementsService: AcknowledgementsServiceProtocol = AcknowledgementsService()

  private(set) lazy var navigationService: NavigationServiceProtocol = NavigationService(services: self)
  private(set) lazy var infoService: InfoServiceProtocol = InfoService(bundleService: bundleService)
  private(set) lazy var yearsService: YearsServiceProtocol = YearsService(networkService: networkService)
  private(set) lazy var updateService: UpdateServiceProtocol = UpdateService(networkService: networkService)
  private(set) lazy var buildingsService: BuildingsServiceProtocol = BuildingsService(bundleService: bundleService)
  private(set) lazy var soonService: SoonServiceProtocol = SoonService(timeService: timeService, persistenceService: _persistenceService)
  private(set) lazy var videosService: VideosServiceProtocol = VideosService(playbackService: playbackService, persistenceService: _persistenceService)
  private(set) lazy var tracksService: TracksServiceProtocol = TracksService(favoritesService: favoritesService, persistenceService: _persistenceService)

  private(set) lazy var networkService: NetworkService = {
    let session = URLSession.shared
    session.configuration.timeoutIntervalForRequest = 30
    session.configuration.timeoutIntervalForResource = 30
    return NetworkService(session: session)
  }()

  #if DEBUG
  lazy var scheduleService: ScheduleServiceProtocol? = ScheduleService(fosdemYear: YearsService.current, networkService: networkService, persistenceService: _persistenceService)
  #else
  private(set) lazy var scheduleService: ScheduleServiceProtocol? = ScheduleService(fosdemYear: yearsService.current, networkService: networkService, persistenceService: _persistenceService)
  #endif

  #if DEBUG
  lazy var timeService: TimeServiceProtocol = TimeService()
  #else
  private(set) lazy var timeService: TimeServiceProtocol = TimeService()
  #endif

  private let _persistenceService: PersistenceService

  init() throws {
    launchService = LaunchService(fosdemYear: YearsService.current)
    try launchService.detectStatus()

    if launchService.didLaunchAfterFosdemYearChange {
      favoritesService.removeAllTracksAndEvents()
    }
    let preloadService = try PreloadService()
    // Remove the database after each update as the new database might contain
    // updates even if the year did not change.
    if launchService.didLaunchAfterUpdate {
      try preloadService.removeDatabase()
    }
    // In the 2020 release, installs and updates where not being recorded. This
    // means that users updating from 2020 to new version will be registered as
    // new installs. The database also needs to be removed for those users too.
    if launchService.didLaunchAfterInstall {
      do {
        try preloadService.removeDatabase()
      } catch {
        if let error = error as? CocoaError, error.code == .fileNoSuchFile {
          // Do nothing
        } else {
          throw error
        }
      }
    }
    try preloadService.preloadDatabaseIfNeeded()

    _persistenceService = try PersistenceService(path: preloadService.databasePath, migrations: .allMigrations)
  }
}

extension BundleService: InfoServiceBundle {}

protocol HasInfoService { var infoService: InfoServiceProtocol { get } }
extension Services: HasInfoService {}

protocol HasSoonService { var soonService: SoonServiceProtocol { get } }
extension Services: HasSoonService {}

protocol HasTimeService { var timeService: TimeServiceProtocol { get } }
extension Services: HasTimeService {}

protocol HasYearsService { var yearsService: YearsServiceProtocol { get } }
extension Services: HasYearsService {}

protocol HasLaunchService { var launchService: LaunchServiceProtocol { get } }
extension Services: HasLaunchService {}

protocol HasTracksService { var tracksService: TracksServiceProtocol { get } }
extension Services: HasTracksService {}

protocol HasUpdateService { var updateService: UpdateServiceProtocol { get } }
extension Services: HasUpdateService {}

protocol HasVideosService { var videosService: VideosServiceProtocol { get } }
extension Services: HasVideosService {}

protocol HasPlaybackService { var playbackService: PlaybackServiceProtocol { get } }
extension Services: HasPlaybackService {}

protocol HasScheduleService { var scheduleService: ScheduleServiceProtocol? { get } }
extension Services: HasScheduleService {}

protocol HasBuildingsService { var buildingsService: BuildingsServiceProtocol { get } }
extension Services: HasBuildingsService {}

protocol HasFavoritesService { var favoritesService: FavoritesServiceProtocol { get } }
extension Services: HasFavoritesService {}

protocol HasNavigationService { var navigationService: NavigationServiceProtocol { get } }
extension Services: HasNavigationService {}

protocol HasAcknowledgementsService { var acknowledgementsService: AcknowledgementsServiceProtocol { get } }
extension Services: HasAcknowledgementsService {}

protocol HasPersistenceService { var persistenceService: PersistenceServiceProtocol { get } }
extension Services: HasPersistenceService {
  var persistenceService: PersistenceServiceProtocol {
    _persistenceService
  }
}
