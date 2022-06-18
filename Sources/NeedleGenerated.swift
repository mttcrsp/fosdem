

import Foundation
import NeedleFoundation
import RIBs
import UIKit

// swiftlint:disable unused_declaration
private let needleDependenciesHash: String? = nil

// MARK: - Registration

public func registerProviderFactories() {
  __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->MapComponent") { component in
    MapDependency7dfd1288fd22c9a72c37Provider(component: component)
  }
  __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent") { component in
    EmptyDependencyProvider(component: component)
  }
  __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->AgendaComponent") { component in
    AgendaDependency232d2546a089120fcfacProvider(component: component)
  }
}

// MARK: - Providers

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
