import AVFAudio
import AVFoundation
import Foundation
import NeedleFoundation
import RIBs

protocol RootDependency: NeedleFoundation.Dependency {}

final class RootComponent: BootstrapComponent {
  var acknowledgementsService: AcknowledgementsServiceProtocol {
    shared { AcknowledgementsService() }
  }

  var buildingsService: BuildingsServiceProtocol {
    shared { BuildingsService(bundleService: bundleService) }
  }

  var bundleService: BundleServiceProtocol {
    shared { BundleService() }
  }

  var favoritesService: FavoritesServiceProtocol {
    shared { FavoritesService() }
  }

  var infoService: InfoServiceProtocol {
    shared { InfoService(bundleService: bundleService) }
  }

  var locationService: LocationServiceProtocol {
    shared { LocationService() }
  }

  var networkService: NetworkService {
    shared {
      let session = URLSession.shared
      session.configuration.timeoutIntervalForRequest = 30
      session.configuration.timeoutIntervalForResource = 30
      return NetworkService(session: session)
    }
  }

  var openService: OpenServiceProtocol {
    shared { OpenService() }
  }

  var playbackService: PlaybackServiceProtocol {
    shared { PlaybackService() }
  }

  var timeService: TimeServiceProtocol {
    shared { TimeService() }
  }

  var yearsService: YearsServiceProtocol {
    shared { YearsService(networkService: networkService) }
  }
}

extension RootComponent {
  var mapBuilder: MapBuildable {
    MapBuilder(componentBuilder: { MapComponent(parent: self) })
  }
  
  func makeAgendaBuilder(with persistenceService: PersistenceServiceProtocol) -> AgendaBuildable {
    AgendaBuilder(componentBuilder: { AgendaComponent(parent: self, persistenceService: persistenceService) })
  }

  func makeMoreBuilder(with persistenceService: PersistenceServiceProtocol) -> MoreBuildable {
    MoreBuilder(componentBuilder: { MoreComponent(parent: self, persistenceService: persistenceService) })
  }

  func makeScheduleBuilder(with persistenceService: PersistenceServiceProtocol) -> ScheduleBuildable {
    ScheduleBuilder(componentBuilder: { ScheduleComponent(parent: self, persistenceService: persistenceService) })
  }
}

extension RootComponent {
  var audioSession: AVAudioSessionProtocol {
    shared { AVAudioSession.sharedInstance() }
  }

  var notificationCenter: NotificationCenter {
    shared { .default }
  }

  var player: AVPlayerProtocol {
    shared { AVPlayer() }
  }
}
