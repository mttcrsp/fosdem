

import Foundation
import NeedleFoundation
import RIBs
import UIKit

// swiftlint:disable unused_declaration
private let needleDependenciesHash: String? = nil

// MARK: - Registration

public func registerProviderFactories() {
  __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent") { component in
    EmptyDependencyProvider(component: component)
  }
  __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->MapComponent") { component in
    _MapDependency7dfd1288fd22c9a72c37Provider(component: component)
  }
}

// MARK: - Providers

private class _MapDependency7dfd1288fd22c9a72c37BaseProvider: _MapDependency {
  var notificationCenter: NotificationCenter {
    rootComponent.notificationCenter
  }

  var bundleService: BundleService {
    rootComponent.bundleService
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
private class _MapDependency7dfd1288fd22c9a72c37Provider: _MapDependency7dfd1288fd22c9a72c37BaseProvider {
  init(component: NeedleFoundation.Scope) {
    super.init(rootComponent: component.parent as! RootComponent)
  }
}
