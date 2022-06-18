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
  func buildMapRouter(withListener listener: MapListener) -> ViewableRouting {
    MapBuilder(componentBuilder: { MapComponent(parent: self) })
      .finalStageBuild(withDynamicDependency: listener)
  }

  func buildAgendaRouter(withPersistenceService persistenceService: PersistenceServiceProtocol, listener: AgendaListener) -> ViewableRouting {
    AgendaBuilder(componentBuilder: { AgendaComponent(parent: self, persistenceService: persistenceService) })
      .finalStageBuild(withDynamicDependency: listener)
  }

  func buildMoreRouter(withPersistenceService persistenceService: PersistenceServiceProtocol) -> ViewableRouting {
    MoreBuilder(componentBuilder: { MoreComponent(parent: self, persistenceService: persistenceService) })
      .build()
  }

  func buildScheduleRouter(withPersistenceService persistenceService: PersistenceServiceProtocol) -> ViewableRouting {
    ScheduleBuilder(componentBuilder: { ScheduleComponent(parent: self, persistenceService: persistenceService) })
      .build()
  }
}
