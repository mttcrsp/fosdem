

import AVFAudio
import AVFoundation
import Foundation
import NeedleFoundation
import RIBs

// swiftlint:disable unused_declaration
private let needleDependenciesHash: String? = nil

// MARK: - Registration

public func registerProviderFactories() {
  __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->ScheduleComponent") { component in
    ScheduleDependencyd09faca1aa36b0d9671fProvider(component: component)
  }
  __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->MoreComponent->YearsComponent") { component in
    YearsDependency772269e846553b24dbddProvider(component: component)
  }
  __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->ScheduleComponent->TrackComponent") { component in
    TrackDependency53efe7b382ad8eff4c2fProvider(component: component)
  }
  __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->MoreComponent") { component in
    MoreDependency8687d23345095611bcfeProvider(component: component)
  }
  __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->MoreComponent->VideosComponent") { component in
    VideosDependency3ccf734c2404aef4d105Provider(component: component)
  }
  __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->MapComponent") { component in
    MapDependency7dfd1288fd22c9a72c37Provider(component: component)
  }
  __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->AgendaComponent->SoonComponent") { component in
    SoonDependency9a2a455ed39148b6e961Provider(component: component)
  }
  __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->MoreComponent->YearsComponent->YearComponent") { component in
    YearDependencyeb270672d5cc37d51804Provider(component: component)
  }
  __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent") { component in
    EmptyDependencyProvider(component: component)
  }
  __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->AgendaComponent") { component in
    AgendaDependency232d2546a089120fcfacProvider(component: component)
  }
  __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->ScheduleComponent->EventComponent") { component in
    EventDependencye5a21d82d937e54bd2e3Provider(component: component)
  }
  __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->ScheduleComponent->TrackComponent->EventComponent") { component in
    EventDependencyaeb7f456efa60b28b73aProvider(component: component)
  }
  __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->MoreComponent->VideosComponent->EventComponent") { component in
    EventDependencyb8f99399bf6feb3e43cdProvider(component: component)
  }
  __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->AgendaComponent->SoonComponent->EventComponent") { component in
    EventDependency67e2f2add8e1e9f6919aProvider(component: component)
  }
  __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->MoreComponent->YearsComponent->YearComponent->EventComponent") { component in
    EventDependencyf0410e86b6055dafd9beProvider(component: component)
  }
  __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->AgendaComponent->EventComponent") { component in
    EventDependency41a87b3fa9d0ea861680Provider(component: component)
  }
}

// MARK: - Providers

private class ScheduleDependencyd09faca1aa36b0d9671fBaseProvider: ScheduleDependency {
  var favoritesService: FavoritesServiceProtocol {
    rootComponent.favoritesService
  }

  var yearsService: YearsServiceProtocol {
    rootComponent.yearsService
  }

  private let rootComponent: RootComponent
  init(rootComponent: RootComponent) {
    self.rootComponent = rootComponent
  }
}

/// ^->RootComponent->ScheduleComponent
private class ScheduleDependencyd09faca1aa36b0d9671fProvider: ScheduleDependencyd09faca1aa36b0d9671fBaseProvider {
  init(component: NeedleFoundation.Scope) {
    super.init(rootComponent: component.parent as! RootComponent)
  }
}

private class YearsDependency772269e846553b24dbddBaseProvider: YearsDependency {
  var networkService: NetworkService {
    rootComponent.networkService
  }

  private let rootComponent: RootComponent
  init(rootComponent: RootComponent) {
    self.rootComponent = rootComponent
  }
}

/// ^->RootComponent->MoreComponent->YearsComponent
private class YearsDependency772269e846553b24dbddProvider: YearsDependency772269e846553b24dbddBaseProvider {
  init(component: NeedleFoundation.Scope) {
    super.init(rootComponent: component.parent.parent as! RootComponent)
  }
}

private class TrackDependency53efe7b382ad8eff4c2fBaseProvider: TrackDependency {
  var favoritesService: FavoritesServiceProtocol {
    rootComponent.favoritesService
  }

  var persistenceService: PersistenceServiceProtocol {
    scheduleComponent.persistenceService
  }

  private let rootComponent: RootComponent
  private let scheduleComponent: ScheduleComponent
  init(rootComponent: RootComponent, scheduleComponent: ScheduleComponent) {
    self.rootComponent = rootComponent
    self.scheduleComponent = scheduleComponent
  }
}

/// ^->RootComponent->ScheduleComponent->TrackComponent
private class TrackDependency53efe7b382ad8eff4c2fProvider: TrackDependency53efe7b382ad8eff4c2fBaseProvider {
  init(component: NeedleFoundation.Scope) {
    super.init(rootComponent: component.parent.parent as! RootComponent, scheduleComponent: component.parent as! ScheduleComponent)
  }
}

private class MoreDependency8687d23345095611bcfeBaseProvider: MoreDependency {
  var acknowledgementsService: AcknowledgementsServiceProtocol {
    rootComponent.acknowledgementsService
  }

  var infoService: InfoServiceProtocol {
    rootComponent.infoService
  }

  var openService: OpenServiceProtocol {
    rootComponent.openService
  }

  var timeService: TimeServiceProtocol {
    rootComponent.timeService
  }

  var yearsService: YearsServiceProtocol {
    rootComponent.yearsService
  }

  private let rootComponent: RootComponent
  init(rootComponent: RootComponent) {
    self.rootComponent = rootComponent
  }
}

/// ^->RootComponent->MoreComponent
private class MoreDependency8687d23345095611bcfeProvider: MoreDependency8687d23345095611bcfeBaseProvider {
  init(component: NeedleFoundation.Scope) {
    super.init(rootComponent: component.parent as! RootComponent)
  }
}

private class VideosDependency3ccf734c2404aef4d105BaseProvider: VideosDependency {
  var persistenceService: PersistenceServiceProtocol {
    moreComponent.persistenceService
  }

  var playbackService: PlaybackServiceProtocol {
    rootComponent.playbackService
  }

  private let moreComponent: MoreComponent
  private let rootComponent: RootComponent
  init(moreComponent: MoreComponent, rootComponent: RootComponent) {
    self.moreComponent = moreComponent
    self.rootComponent = rootComponent
  }
}

/// ^->RootComponent->MoreComponent->VideosComponent
private class VideosDependency3ccf734c2404aef4d105Provider: VideosDependency3ccf734c2404aef4d105BaseProvider {
  init(component: NeedleFoundation.Scope) {
    super.init(moreComponent: component.parent as! MoreComponent, rootComponent: component.parent.parent as! RootComponent)
  }
}

private class MapDependency7dfd1288fd22c9a72c37BaseProvider: MapDependency {
  var buildingsService: BuildingsServiceProtocol {
    rootComponent.buildingsService
  }

  var bundleService: BundleServiceProtocol {
    rootComponent.bundleService
  }

  var locationService: LocationServiceProtocol {
    rootComponent.locationService
  }

  var openService: OpenServiceProtocol {
    rootComponent.openService
  }

  private let rootComponent: RootComponent
  init(rootComponent: RootComponent) {
    self.rootComponent = rootComponent
  }
}

/// ^->RootComponent->MapComponent
private class MapDependency7dfd1288fd22c9a72c37Provider: MapDependency7dfd1288fd22c9a72c37BaseProvider {
  init(component: NeedleFoundation.Scope) {
    super.init(rootComponent: component.parent as! RootComponent)
  }
}

private class SoonDependency9a2a455ed39148b6e961BaseProvider: SoonDependency {
  var timeService: TimeServiceProtocol {
    rootComponent.timeService
  }

  var favoritesService: FavoritesServiceProtocol {
    rootComponent.favoritesService
  }

  var persistenceService: PersistenceServiceProtocol {
    agendaComponent.persistenceService
  }

  private let agendaComponent: AgendaComponent
  private let rootComponent: RootComponent
  init(agendaComponent: AgendaComponent, rootComponent: RootComponent) {
    self.agendaComponent = agendaComponent
    self.rootComponent = rootComponent
  }
}

/// ^->RootComponent->AgendaComponent->SoonComponent
private class SoonDependency9a2a455ed39148b6e961Provider: SoonDependency9a2a455ed39148b6e961BaseProvider {
  init(component: NeedleFoundation.Scope) {
    super.init(agendaComponent: component.parent as! AgendaComponent, rootComponent: component.parent.parent as! RootComponent)
  }
}

private class YearDependencyeb270672d5cc37d51804BaseProvider: YearDependency {
  var yearsService: YearsServiceProtocol {
    yearsComponent.yearsService
  }

  private let yearsComponent: YearsComponent
  init(yearsComponent: YearsComponent) {
    self.yearsComponent = yearsComponent
  }
}

/// ^->RootComponent->MoreComponent->YearsComponent->YearComponent
private class YearDependencyeb270672d5cc37d51804Provider: YearDependencyeb270672d5cc37d51804BaseProvider {
  init(component: NeedleFoundation.Scope) {
    super.init(yearsComponent: component.parent as! YearsComponent)
  }
}

private class AgendaDependency232d2546a089120fcfacBaseProvider: AgendaDependency {
  var favoritesService: FavoritesServiceProtocol {
    rootComponent.favoritesService
  }

  var timeService: TimeServiceProtocol {
    rootComponent.timeService
  }

  private let rootComponent: RootComponent
  init(rootComponent: RootComponent) {
    self.rootComponent = rootComponent
  }
}

/// ^->RootComponent->AgendaComponent
private class AgendaDependency232d2546a089120fcfacProvider: AgendaDependency232d2546a089120fcfacBaseProvider {
  init(component: NeedleFoundation.Scope) {
    super.init(rootComponent: component.parent as! RootComponent)
  }
}

private class EventDependencye5a21d82d937e54bd2e3BaseProvider: EventDependency {
  var player: AVPlayerProtocol {
    rootComponent.player
  }

  var audioSession: AVAudioSessionProtocol {
    rootComponent.audioSession
  }

  var favoritesService: FavoritesServiceProtocol {
    rootComponent.favoritesService
  }

  var notificationCenter: NotificationCenter {
    rootComponent.notificationCenter
  }

  var playbackService: PlaybackServiceProtocol {
    rootComponent.playbackService
  }

  var timeService: TimeServiceProtocol {
    rootComponent.timeService
  }

  private let rootComponent: RootComponent
  init(rootComponent: RootComponent) {
    self.rootComponent = rootComponent
  }
}

/// ^->RootComponent->ScheduleComponent->EventComponent
private class EventDependencye5a21d82d937e54bd2e3Provider: EventDependencye5a21d82d937e54bd2e3BaseProvider {
  init(component: NeedleFoundation.Scope) {
    super.init(rootComponent: component.parent.parent as! RootComponent)
  }
}

/// ^->RootComponent->ScheduleComponent->TrackComponent->EventComponent
private class EventDependencyaeb7f456efa60b28b73aProvider: EventDependencye5a21d82d937e54bd2e3BaseProvider {
  init(component: NeedleFoundation.Scope) {
    super.init(rootComponent: component.parent.parent.parent as! RootComponent)
  }
}

/// ^->RootComponent->MoreComponent->VideosComponent->EventComponent
private class EventDependencyb8f99399bf6feb3e43cdProvider: EventDependencye5a21d82d937e54bd2e3BaseProvider {
  init(component: NeedleFoundation.Scope) {
    super.init(rootComponent: component.parent.parent.parent as! RootComponent)
  }
}

/// ^->RootComponent->AgendaComponent->SoonComponent->EventComponent
private class EventDependency67e2f2add8e1e9f6919aProvider: EventDependencye5a21d82d937e54bd2e3BaseProvider {
  init(component: NeedleFoundation.Scope) {
    super.init(rootComponent: component.parent.parent.parent as! RootComponent)
  }
}

/// ^->RootComponent->MoreComponent->YearsComponent->YearComponent->EventComponent
private class EventDependencyf0410e86b6055dafd9beProvider: EventDependencye5a21d82d937e54bd2e3BaseProvider {
  init(component: NeedleFoundation.Scope) {
    super.init(rootComponent: component.parent.parent.parent.parent as! RootComponent)
  }
}

/// ^->RootComponent->AgendaComponent->EventComponent
private class EventDependency41a87b3fa9d0ea861680Provider: EventDependencye5a21d82d937e54bd2e3BaseProvider {
  init(component: NeedleFoundation.Scope) {
    super.init(rootComponent: component.parent.parent as! RootComponent)
  }
}
