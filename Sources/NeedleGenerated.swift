

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
}

// MARK: - Providers

private class MapDependency7dfd1288fd22c9a72c37BaseProvider: MapDependency {
  init() {}
}

/// ^->RootComponent->MapComponent
private class MapDependency7dfd1288fd22c9a72c37Provider: MapDependency7dfd1288fd22c9a72c37BaseProvider {
  init(component _: NeedleFoundation.Scope) {
    super.init()
  }
}
