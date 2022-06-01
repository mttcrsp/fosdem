import AVFoundation
import Foundation

class Services {
  let bundleService = BundleService()
  let openService: OpenServiceProtocol = OpenService()
  let locationService: LocationServiceProtocol = LocationService()
  let playbackService: PlaybackServiceProtocol = PlaybackService()
  let favoritesService: FavoritesServiceProtocol = FavoritesService()
  let acknowledgementsService: AcknowledgementsServiceProtocol = AcknowledgementsService()

  private(set) lazy var infoService: InfoServiceProtocol = InfoService(bundleService: bundleService)
  private(set) lazy var yearsService: YearsServiceProtocol = YearsService(networkService: networkService)
  private(set) lazy var updateService: UpdateServiceProtocol = UpdateService(networkService: networkService)
  private(set) lazy var buildingsService: BuildingsServiceProtocol = BuildingsService(bundleService: bundleService)
  private(set) lazy var soonService: SoonServiceProtocol = SoonService(timeService: timeService, persistenceService: _persistenceService)
  private(set) lazy var videosService: VideosServiceProtocol = VideosService(playbackService: playbackService, persistenceService: _persistenceService)
  private(set) lazy var tracksService: TracksServiceProtocol = TracksService(favoritesService: favoritesService, persistenceService: _persistenceService)
  private(set) lazy var scheduleService: ScheduleServiceProtocol = ScheduleService(fosdemYear: YearsService.current, networkService: networkService, persistenceService: _persistenceService)

  let audioSession: AVAudioSessionProtocol = AVAudioSession.sharedInstance()
  let notificationCenter: NotificationCenter = .default
  let player: AVPlayerProtocol = AVPlayer()

  private(set) lazy var agendaBuilder: AgendaBuildable = AgendaBuilder(dependency: self)
  private(set) lazy var eventBuilder: EventBuildable = EventBuilder(dependency: self)
  private(set) lazy var mapBuilder: MapBuildable = MapBuilder(dependency: self)
  private(set) lazy var moreBuilder: MoreBuildable = MoreBuilder(dependency: self)
  private(set) lazy var scheduleBuilder: ScheduleBuildable = ScheduleBuilder(dependency: self)
  private(set) lazy var searchBuilder: SearchBuildable = SearchBuilder(dependency: self)
  private(set) lazy var soonBuilder: SoonBuildable = SoonBuilder(dependency: self)
  private(set) lazy var trackBuilder: TrackBuildable = TrackBuilder(dependency: self)
  private(set) lazy var videosBuilder: VideosBuildable = VideosBuilder(dependency: self)
  private(set) lazy var yearBuilder: YearBuildable = YearBuilder(dependency: self)
  private(set) lazy var yearsBuilder: YearsBuildable = YearsBuilder(dependency: self)

  private(set) lazy var networkService: NetworkService = {
    let session = URLSession.shared
    session.configuration.timeoutIntervalForRequest = 30
    session.configuration.timeoutIntervalForResource = 30
    return NetworkService(session: session)
  }()

  #if DEBUG
  lazy var timeService: TimeServiceProtocol = TimeService()
  #else
  private(set) lazy var timeService: TimeServiceProtocol = TimeService()
  #endif

  private let _persistenceService: PersistenceService

  init() throws {
    let launchService = LaunchService(fosdemYear: YearsService.current)
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

extension Services {
  var persistenceService: PersistenceServiceProtocol {
    _persistenceService
  }
}

extension Services: AgendaDependency {}
extension Services: EventDependency {}
extension Services: MapDependency {}
extension Services: MoreDependency {}
extension Services: RootDependency {}
extension Services: ScheduleDependency {}
extension Services: SearchDependency {}
extension Services: SoonDependency {}
extension Services: TrackDependency {}
extension Services: VideosDependency {}
extension Services: YearDependency {}
extension Services: YearsDependency {}

extension BundleService: InfoServiceBundle {}
