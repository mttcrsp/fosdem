import Foundation

final class Services {
  let launchService: LaunchServiceProtocol

  let bundleService = BundleService()
  let playbackService: PlaybackServiceProtocol = PlaybackService()
  let yearsService: YearsServiceProtocol = YearsService()
  let favoritesService: FavoritesServiceProtocol = FavoritesService()
  let acknowledgementsService: AcknowledgementsServiceProtocol = AcknowledgementsService()

  private(set) lazy var navigationService: NavigationServiceProtocol = NavigationService(services: self)
  private(set) lazy var infoService: InfoServiceProtocol = InfoService(bundleService: bundleService)
  private(set) lazy var updateService: UpdateServiceProtocol = UpdateService(networkService: networkService)
  private(set) lazy var buildingsService: BuildingsServiceProtocol = BuildingsService(bundleService: bundleService)
  private(set) lazy var tracksService: TracksServiceProtocol = TracksService(favoritesService: favoritesService, persistenceService: _persistenceService)

  private(set) lazy var networkService: NetworkService = {
    let session = URLSession.shared
    session.configuration.timeoutIntervalForRequest = 30
    session.configuration.timeoutIntervalForResource = 30
    return NetworkService(session: session)
  }()

  #if DEBUG
  let debugService = DebugService()
  let testsService = TestsService()
  #endif

  private(set) lazy var scheduleService: ScheduleServiceProtocol? = {
    var scheduleService: ScheduleService? = ScheduleService(fosdemYear: yearsService.current, networkService: networkService, persistenceService: _persistenceService)
    #if DEBUG
    if !testsService.shouldUpdateSchedule {
      scheduleService = nil
    }
    #endif
    return scheduleService
  }()

  private(set) lazy var liveService: LiveServiceProtocol = {
    var liveService = LiveService()
    #if DEBUG
    if let timeInterval = testsService.liveTimerInterval {
      liveService = LiveService(timeInterval: timeInterval)
    }
    #endif
    return liveService
  }()

  private let _persistenceService: PersistenceService

  init() throws {
    launchService = LaunchService(fosdemYear: yearsService.current)

    #if DEBUG
    if testsService.shouldResetDefaults, let name = Bundle.main.bundleIdentifier {
      UserDefaults.standard.removePersistentDomain(forName: name)
    }

    if !testsService.shouldDiplayOnboarding {
      launchService.markAsLaunched()
    }
    #endif

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

    #if DEBUG
    if let identifiers = testsService.favoriteEventsIdentifiers {
      favoritesService.setEventsIdentifiers(identifiers)
    }

    if let identifiers = testsService.favoriteTracksIdentifiers {
      favoritesService.setTracksIdentifiers(identifiers)
    }

    if let date = testsService.date {
      debugService.override(date)
    }

    if let dates = testsService.dates {
      testsService.startTogglingDates(dates) { date in
        self.debugService.override(date)
      }
    }

    if let video = testsService.video {
      do {
        let directory = FileManager.default.temporaryDirectory
        let url = directory.appendingPathComponent("test.mp4")
        try video.write(to: url)

        let links = [Link(name: "test", url: url)]
        let write = UpdateLinksForEvent(eventID: 11717, links: links)
        try persistenceService.performWriteSync(write)
      } catch {
        assertionFailure(error.localizedDescription)
      }
    }
    #endif
  }
}

extension BundleService: InfoServiceBundle {}

#if DEBUG
private extension FavoritesServiceProtocol {
  func setTracksIdentifiers(_ newTracksIdentifiers: Set<String>) {
    for identifier in tracksIdentifiers {
      removeTrack(withIdentifier: identifier)
    }

    for identifier in newTracksIdentifiers {
      addTrack(withIdentifier: identifier)
    }
  }

  func setEventsIdentifiers(_ newEventsIdentifiers: Set<Int>) {
    for identifier in eventsIdentifiers {
      removeEvent(withIdentifier: identifier)
    }

    for identifier in newEventsIdentifiers {
      addEvent(withIdentifier: identifier)
    }
  }
}

#endif

protocol HasInfoService { var infoService: InfoServiceProtocol { get } }
extension Services: HasInfoService {}

protocol HasLiveService { var liveService: LiveServiceProtocol { get } }
extension Services: HasLiveService {}

protocol HasLaunchService { var launchService: LaunchServiceProtocol { get } }
extension Services: HasLaunchService {}

protocol HasYearsService { var yearsService: YearsServiceProtocol { get } }
extension Services: HasYearsService {}

protocol HasTracksService { var tracksService: TracksServiceProtocol { get } }
extension Services: HasTracksService {}

protocol HasUpdateService { var updateService: UpdateServiceProtocol { get } }
extension Services: HasUpdateService {}

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

#if DEBUG

protocol HasDebugService { var debugService: DebugService { get } }
extension Services: HasDebugService {}

#endif
