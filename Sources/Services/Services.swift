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
  private(set) lazy var soonService: SoonServiceProtocol = SoonService(timeService: timeService, persistenceService: persistenceService)
  private(set) lazy var videosService: VideosServiceProtocol = VideosService(playbackService: playbackService, persistenceService: persistenceService)
  private(set) lazy var tracksService: TracksServiceProtocol = TracksService(favoritesService: favoritesService, persistenceService: persistenceService)
  private(set) lazy var scheduleService: ScheduleServiceProtocol = ScheduleService(fosdemYear: YearsService.current, networkService: networkService, persistenceService: _persistenceService)

  let audioSession: AVAudioSessionProtocol = AVAudioSession.sharedInstance()
  let notificationCenter: NotificationCenter = .default
  let player: AVPlayerProtocol = AVPlayer()

  private(set) lazy var eventBuilder: EventBuildable = EventBuilder(dependency: self)
  private(set) lazy var searchBuilder: SearchBuildable = SearchBuilder(dependency: self)
  private(set) lazy var soonBuilder: SoonBuildable = SoonBuilder(dependency: self)
  private(set) lazy var trackBuilder: TrackBuildable = TrackBuilder(dependency: self)
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

  var persistenceService: PersistenceServiceProtocol {
    _persistenceService
  }

  init(persistenceService: PersistenceService) {
    _persistenceService = persistenceService
  }
}

extension Services: AgendaDependency {}
extension Services: EventDependency {}
extension Services: MoreDependency {}
extension Services: ScheduleDependency {}
extension Services: SearchDependency {}
extension Services: SoonDependency {}
extension Services: TrackDependency {}
extension Services: VideosDependency {}
extension Services: YearDependency {}
extension Services: YearsDependency {}
