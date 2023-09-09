import Foundation

class Clients {
  let launchClient: LaunchClientProtocol

  let bundleClient = BundleClient()
  let openClient: OpenClientProtocol = OpenClient()
  let playbackClient: PlaybackClientProtocol = PlaybackClient()
  let acknowledgementsClient: AcknowledgementsClientProtocol = AcknowledgementsClient()
  let preferencesClient: PreferencesClientProtocol = PreferencesClient()
  let ubiquitousPreferencesClient: UbiquitousPreferencesClientProtocol = UbiquitousPreferencesClient()

  private(set) lazy var navigationClient: NavigationClientProtocol = NavigationClient(clients: self)
  private(set) lazy var infoClient: InfoClientProtocol = InfoClient(bundleClient: bundleClient)
  private(set) lazy var yearsClient: YearsClientProtocol = YearsClient(networkClient: networkClient)
  private(set) lazy var updateClient: UpdateClientProtocol = UpdateClient(networkClient: networkClient)
  private(set) lazy var buildingsClient: BuildingsClientProtocol = BuildingsClient(bundleClient: bundleClient)
  private(set) lazy var soonClient: SoonClientProtocol = SoonClient(timeClient: timeClient, persistenceClient: _persistenceClient)
  private(set) lazy var videosClient: VideosClientProtocol = VideosClient(playbackClient: playbackClient, persistenceClient: _persistenceClient)
  private(set) lazy var tracksClient: TracksClientProtocol = TracksClient(favoritesClient: favoritesClient, persistenceClient: _persistenceClient)
  private(set) lazy var scheduleClient: ScheduleClientProtocol = ScheduleClient(fosdemYear: YearsClient.current, networkClient: networkClient, persistenceClient: _persistenceClient)
  private(set) lazy var favoritesClient: FavoritesClientProtocol = FavoritesClient(fosdemYear: YearsClient.current, preferencesClient: preferencesClient, ubiquitousPreferencesClient: ubiquitousPreferencesClient, timeClient: timeClient)

  private(set) lazy var networkClient: NetworkClient = {
    let session = URLSession.shared
    session.configuration.timeoutIntervalForRequest = 30
    session.configuration.timeoutIntervalForResource = 30
    return NetworkClient(session: session)
  }()

  #if DEBUG
  lazy var timeClient: TimeClientProtocol = TimeClient()
  #else
  private(set) lazy var timeClient: TimeClientProtocol = TimeClient()
  #endif

  private let _persistenceClient: PersistenceClient

  init() throws {
    launchClient = LaunchClient(fosdemYear: YearsClient.current)
    try launchClient.detectStatus()

    let preloadClient = try PreloadClient()
    // Remove the database after each update as the new database might contain
    // updates even if the year did not change.
    if launchClient.didLaunchAfterUpdate() {
      try preloadClient.removeDatabase()
    }
    // In the 2020 release, installs and updates where not being recorded. This
    // means that users updating from 2020 to new version will be registered as
    // new installs. The database also needs to be removed for those users too.
    if launchClient.didLaunchAfterInstall() {
      do {
        try preloadClient.removeDatabase()
      } catch {
        if let error = error as? CocoaError, error.code == .fileNoSuchFile {
          // Do nothing
        } else {
          throw error
        }
      }
    }
    try preloadClient.preloadDatabaseIfNeeded()

    _persistenceClient = PersistenceClient()
    try _persistenceClient.load(try preloadClient.databasePath())

    if launchClient.didLaunchAfterFosdemYearChange() {
      favoritesClient.removeAllTracksAndEvents()
    }
    favoritesClient.migrate()
  }
}

extension Clients: HasOpenClient, HasInfoClient, HasSoonClient, HasTimeClient, HasYearsClient, HasLaunchClient, HasTracksClient, HasUpdateClient, HasVideosClient, HasPlaybackClient, HasScheduleClient, HasBuildingsClient, HasFavoritesClient, HasNavigationClient, HasAcknowledgementsClient, HasUbiquitousPreferencesClient {}

extension Clients: HasPersistenceClient {
  var persistenceClient: PersistenceClientProtocol {
    _persistenceClient
  }
}

extension BundleClient: InfoClientBundle {}
