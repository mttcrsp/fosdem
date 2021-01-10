import Foundation

protocol LaunchServiceBundle {
  var bundleShortVersion: String? { get }
}

protocol LaunchServiceDefaults: AnyObject {
  func string(forKey key: String) -> String?
  func set(_ value: Any?, forKey defaultName: String)
}

final class LaunchService {
  enum Error: CustomNSError {
    case versionDetectionFailed
  }

  private(set) var didLaunchAfterUpdate = false
  private(set) var didLaunchAfterInstall = false

  private let bundle: LaunchServiceBundle
  private let defaults: LaunchServiceDefaults

  init(bundle: LaunchServiceBundle = Bundle.main, defaults: LaunchServiceDefaults = UserDefaults.standard) {
    self.bundle = bundle
    self.defaults = defaults
  }

  func detectStatus() throws {
    guard let bundleShortVersion = bundle.bundleShortVersion else {
      throw Error.versionDetectionFailed
    }

    switch defaults.latestBundleShortVersionKey {
    case .some(bundleShortVersion):
      didLaunchAfterUpdate = false
      didLaunchAfterInstall = false
    case .some:
      didLaunchAfterUpdate = true
      didLaunchAfterInstall = false
    case nil:
      didLaunchAfterUpdate = false
      didLaunchAfterInstall = true
    }

    defaults.latestBundleShortVersionKey = bundleShortVersion
  }
}

extension LaunchServiceDefaults {
  var latestBundleShortVersionKey: String? {
    get { string(forKey: .latestBundleShortVersionKey) }
    set { set(newValue, forKey: .latestBundleShortVersionKey) }
  }
}

private extension String {
  static var latestBundleShortVersionKey: String { "LATEST_BUNDLE_SHORT_VERSION" }
}

extension Bundle: LaunchServiceBundle {}

extension UserDefaults: LaunchServiceDefaults {}
