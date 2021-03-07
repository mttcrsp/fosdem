@testable
import Core
import XCTest

final class LaunchServiceTests: XCTestCase {
  func testDetect() throws {
    let defaults = LaunchServiceDefaultsMock()
    let bundle = LaunchServiceBundleMock()
    bundle.bundleShortVersion = "1.0.0"

    let service = LaunchService(fosdemYear: 2021, bundle: bundle, defaults: defaults)
    try service.detectStatus()
    XCTAssertFalse(service.didLaunchAfterUpdate)
    XCTAssertTrue(service.didLaunchAfterInstall)

    try service.detectStatus()
    XCTAssertFalse(service.didLaunchAfterUpdate)
    XCTAssertFalse(service.didLaunchAfterInstall)

    bundle.bundleShortVersion = "1.0.1"
    try service.detectStatus()
    XCTAssertTrue(service.didLaunchAfterUpdate)
    XCTAssertFalse(service.didLaunchAfterInstall)

    try service.detectStatus()
    XCTAssertFalse(service.didLaunchAfterUpdate)
    XCTAssertFalse(service.didLaunchAfterInstall)
  }

  func testDetectMissingBundleShortVersion() {
    let bundle = LaunchServiceBundleMock()
    let defaults = LaunchServiceDefaultsMock()
    let service = LaunchService(fosdemYear: 2021, bundle: bundle, defaults: defaults)
    do {
      try service.detectStatus()
    } catch {
      let error1 = error as NSError
      let error2 = LaunchService.Error.versionDetectionFailed as NSError
      XCTAssertEqual(error1, error2)
    }
  }
}

final class LaunchServiceBundleMock: LaunchServiceBundle {
  var bundleShortVersion: String?
}

final class LaunchServiceDefaultsMock: LaunchServiceDefaults {
  private var dictionary: [String: String] = [:]

  func string(forKey key: String) -> String? {
    dictionary[key]
  }

  func set(_ value: Any?, forKey defaultName: String) {
    dictionary[defaultName] = value as? String
  }
}
