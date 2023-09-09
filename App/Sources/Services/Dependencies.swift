import Dependencies
import Foundation

extension AcknowledgementsClient: DependencyKey {
  static let liveValue = AcknowledgementsClient()
}

extension DependencyValues {
  var acknowledgementsClient: AcknowledgementsClient {
    get { self[AcknowledgementsClient.self] }
    set { self[AcknowledgementsClient.self] = newValue }
  }
}

extension BuildingsClient: DependencyKey {
  static let liveValue = BuildingsClient(
    bundleClient: BundleClient.liveValue
  )
}

extension DependencyValues {
  var buildingsClient: BuildingsClient {
    get { self[BuildingsClient.self] }
    set { self[BuildingsClient.self] = newValue }
  }
}

extension BundleClient: DependencyKey {
  static let liveValue = BundleClient()
}

extension DependencyValues {
  var bundleClient: BundleClient {
    get { self[BundleClient.self] }
    set { self[BundleClient.self] = newValue }
  }
}

extension FavoritesClient: DependencyKey {
  static let liveValue = FavoritesClient(
    preferencesClient: PreferencesClient.liveValue,
    ubiquitousPreferencesClient: UbiquitousPreferencesClient.liveValue,
    timeClient: TimeClient.liveValue
  )
}

extension DependencyValues {
  var favoritesClient: FavoritesClient {
    get { self[FavoritesClient.self] }
    set { self[FavoritesClient.self] = newValue }
  }
}

extension InfoClient: DependencyKey {
  static let liveValue = InfoClient(
    bundleClient: BundleClient.liveValue
  )
}

extension DependencyValues {
  var infoClient: InfoClient {
    get { self[InfoClient.self] }
    set { self[InfoClient.self] = newValue }
  }
}

extension LaunchClient: DependencyKey {
  static let liveValue = LaunchClient()
}

extension DependencyValues {
  var launchClient: LaunchClient {
    get { self[LaunchClient.self] }
    set { self[LaunchClient.self] = newValue }
  }
}

extension NavigationClient: DependencyKey {
  static let liveValue = NavigationClient()
}

extension DependencyValues {
  var navigationClient: NavigationClient {
    get { self[NavigationClient.self] }
    set { self[NavigationClient.self] = newValue }
  }
}

extension NetworkClient: DependencyKey {
  static let liveValue = NetworkClient()
}

extension DependencyValues {
  var networkClient: NetworkClient {
    get { self[NetworkClient.self] }
    set { self[NetworkClient.self] = newValue }
  }
}

extension OpenClient: DependencyKey {
  static let liveValue = OpenClient()
}

extension DependencyValues {
  var openClient: OpenClient {
    get { self[OpenClient.self] }
    set { self[OpenClient.self] = newValue }
  }
}

extension PersistenceClient: DependencyKey {
  static let liveValue = PersistenceClient()
}

extension DependencyValues {
  var persistenceClient: PersistenceClient {
    get { self[PersistenceClient.self] }
    set { self[PersistenceClient.self] = newValue }
  }
}

extension PlaybackClient: DependencyKey {
  static let liveValue = PlaybackClient()
}

extension DependencyValues {
  var playbackClient: PlaybackClient {
    get { self[PlaybackClient.self] }
    set { self[PlaybackClient.self] = newValue }
  }
}

extension PreferencesClient: DependencyKey {
  static let liveValue = PreferencesClient()
}

extension DependencyValues {
  var preferencesClient: PreferencesClient {
    get { self[PreferencesClient.self] }
    set { self[PreferencesClient.self] = newValue }
  }
}

extension PreloadClient: DependencyKey {
  static let liveValue = PreloadClient()
}

extension DependencyValues {
  var preloadClient: PreloadClient {
    get { self[PreloadClient.self] }
    set { self[PreloadClient.self] = newValue }
  }
}

extension ScheduleClient: DependencyKey {
  static let liveValue = ScheduleClient(
    networkClient: NetworkClient.liveValue,
    persistenceClient: PersistenceClient.liveValue
  )
}

extension DependencyValues {
  var scheduleClient: ScheduleClient {
    get { self[ScheduleClient.self] }
    set { self[ScheduleClient.self] = newValue }
  }
}

extension SoonClient: DependencyKey {
  static let liveValue = SoonClient(
    timeClient: TimeClient.liveValue,
    persistenceClient: PersistenceClient.liveValue
  )
}

extension DependencyValues {
  var soonClient: SoonClient {
    get { self[SoonClient.self] }
    set { self[SoonClient.self] = newValue }
  }
}

extension TimeClient: DependencyKey {
  static let liveValue = TimeClient()
}

extension DependencyValues {
  var timeClient: TimeClient {
    get { self[TimeClient.self] }
    set { self[TimeClient.self] = newValue }
  }
}

extension TracksClient: DependencyKey {
  static let liveValue = TracksClient(
    favoritesClient: FavoritesClient.liveValue,
    persistenceClient: PersistenceClient.liveValue
  )
}

extension DependencyValues {
  var tracksClient: TracksClient {
    get { self[TracksClient.self] }
    set { self[TracksClient.self] = newValue }
  }
}

extension UbiquitousPreferencesClient: DependencyKey {
  static let liveValue = UbiquitousPreferencesClient()
}

extension DependencyValues {
  var ubiquitousPreferencesClient: UbiquitousPreferencesClient {
    get { self[UbiquitousPreferencesClient.self] }
    set { self[UbiquitousPreferencesClient.self] = newValue }
  }
}

extension UpdateClient: DependencyKey {
  static let liveValue = UpdateClient(
    networkClient: NetworkClient.liveValue
  )
}

extension DependencyValues {
  var updateClient: UpdateClient {
    get { self[UpdateClient.self] }
    set { self[UpdateClient.self] = newValue }
  }
}

extension URLSession: DependencyKey {
  public static let liveValue: URLSession = {
    let session = URLSession.shared
    session.configuration.timeoutIntervalForRequest = 30
    session.configuration.timeoutIntervalForResource = 30
    return session
  }()
}

extension DependencyValues {
  var urlSession: URLSession {
    get { self[URLSession.self] }
    set { self[URLSession.self] = newValue }
  }
}

extension VideosClient: DependencyKey {
  static let liveValue = VideosClient(
    playbackClient: PlaybackClient.liveValue,
    persistenceClient: PersistenceClient.liveValue
  )
}

extension DependencyValues {
  var videosClient: VideosClient {
    get { self[VideosClient.self] }
    set { self[VideosClient.self] = newValue }
  }
}

extension YearsClient: DependencyKey {
  static let liveValue = YearsClient(
    networkClient: NetworkClient.liveValue
  )
}

extension DependencyValues {
  var yearsClient: YearsClient {
    get { self[YearsClient.self] }
    set { self[YearsClient.self] = newValue }
  }
}
