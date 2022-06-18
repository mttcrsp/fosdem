import Foundation
import ProjectDescription

let isCI: Bool = {
  if let path = ProcessInfo.processInfo.environment["DYLD_LIBRARY_PATH"], path.contains("/Users/runner") {
    return true
  } else {
    return false
  }
}()

let mockolo = TargetScript.pre(
  script: "./run-mockolo",
  name: "Mockolo"
)

let needleScript = TargetScript.pre(
  script: "export SOURCEKIT_LOGGING=0 && needle generate Sources/NeedleGenerated.swift Sources/",
  name: "Needle"
)

let swiftFormat = TargetScript.post(
  script: "swiftformat .",
  name: "SwiftFormat"
)

let grdb = Package.remote(
  url: "https://github.com/mttcrsp/GRDB.swift",
  requirement: .branch("master")
)

let needle = Package.remote(
  url: "https://github.com/uber/needle",
  requirement: .branch("master")
)

let ribs = Package.remote(
  url: "https://github.com/uber/ribs",
  requirement: .branch("main")
)

let rxSwift = Package.remote(
  url: "https://github.com/ReactiveX/RxSwift",
  requirement: .branch("main")
)

let snapshotTesting = Package.remote(
  url: "https://github.com/pointfreeco/swift-snapshot-testing",
  requirement: .branch("main")
)

let app = Target(
  name: "FOSDEM",
  platform: .iOS,
  product: .app,
  bundleId: "com.mttcrsp.fosdem",
  deploymentTarget: .iOS(targetVersion: "11.0", devices: [.iphone, .ipad]),
  infoPlist: .extendingDefault(with: [
    "CFBundleVersion": "1",
    "CFBundleShortVersionString": "1.2.0",
    "UIBackgroundModes": .array(["audio"]),
    "ITSAppUsesNonExemptEncryption": .boolean(false),
    "UILaunchStoryboardName": .string("LaunchScreen"),
    "NSAppTransportSecurity": .dictionary([
      "NSAllowsArbitraryLoads": .boolean(true),
    ]),
    "NSLocationWhenInUseUsageDescription": "The app uses your location data to display your current position within a map. Location data is never recorded and will never leave the app.",
    "UISupportedInterfaceOrientations~ipad": .array([
      "UIInterfaceOrientationPortrait",
      "UIInterfaceOrientationLandscapeLeft",
      "UIInterfaceOrientationLandscapeRight",
      "UIInterfaceOrientationPortraitUpsideDown",
    ]),
    "UISupportedInterfaceOrientations~iphone": .array([
      "UIInterfaceOrientationPortrait",
      "UIInterfaceOrientationLandscapeLeft",
      "UIInterfaceOrientationLandscapeRight",
    ]),
  ]),
  sources: ["Sources/**/*"],
  resources: ["Resources/**/*"],
  scripts: isCI ? [] : [mockolo, needleScript, swiftFormat],
  dependencies: [
    .package(product: "GRDB"),
    .package(product: "NeedleFoundation"),
    .package(product: "RIBs"),
    .package(product: "RxSwift"),
  ],
  settings: .settings(base: [
    "DEVELOPMENT_TEAM": "3CM92FF2C5",
    "PRODUCT_MODULE_NAME": "Fosdem",
  ]),
  environment: ["ENABLE_SCHEDULE_UPDATES": "1", "ENABLE_ONBOARDING": "1"]
)

let appTests = Target(
  name: "Tests",
  platform: app.platform,
  product: .unitTests,
  bundleId: "\(app.bundleId).tests",
  deploymentTarget: app.deploymentTarget,
  infoPlist: .default,
  sources: ["Tests/**", "Mocks/**"],
  resources: ["Tests/Resources/**/*", "Resources/Buildings/**/*"],
  scripts: [swiftFormat],
  dependencies: [.target(name: app.name)]
)

let appUITests = Target(
  name: "UITests",
  platform: app.platform,
  product: .uiTests,
  bundleId: "\(app.bundleId).uitests",
  deploymentTarget: app.deploymentTarget,
  infoPlist: .default,
  sources: ["UITests/**/*", "Tests/BundleDataLoader.swift"],
  resources: ["UITests/Resources/**/*"],
  scripts: [swiftFormat],
  dependencies: [.target(name: app.name)]
)

let appSnapshotTests = Target(
  name: "SnapshotTests",
  platform: app.platform,
  product: .unitTests,
  bundleId: "\(app.bundleId).snapshottests",
  deploymentTarget: app.deploymentTarget,
  infoPlist: .default,
  sources: ["SnapshotTests/**", "Mocks/**"],
  scripts: [swiftFormat],
  dependencies: [
    .target(name: app.name),
    .package(product: "SnapshotTesting"),
  ]
)

let dbGenerator = Target(
  name: "GenerateDB",
  platform: .macOS,
  product: .commandLineTool,
  bundleId: "\(app.bundleId).db-generator",
  deploymentTarget: .macOS(targetVersion: "10.13"),
  infoPlist: .default,
  sources: [
    "Scripts/GenerateDB.swift",
    "Sources/Models/Migrations/*",
    "Sources/Models/Queries/*",
    "Sources/Models/Tables/*",
    "Sources/Models/Attachment.swift",
    "Sources/Models/Conference.swift",
    "Sources/Models/Day.swift",
    "Sources/Models/Event.swift",
    "Sources/Models/Link.swift",
    "Sources/Models/Participation.swift",
    "Sources/Models/Person.swift",
    "Sources/Models/Room.swift",
    "Sources/Models/Schedule.swift",
    "Sources/Models/ScheduleXMLParser.swift",
    "Sources/Models/Track.swift",
    "Sources/Models/Requests/ScheduleRequest.swift",
    "Sources/Services/NetworkService.swift",
    "Sources/Services/PersistenceService.swift",
    "Sources/Extensions/FOSDEMStrings+Extensions.swift",
    "Sources/Extensions/DateFormatter+Extensions.swift",
    "Sources/Extensions/DateComponentsFormatter+Extensions.swift",
    "Derived/Sources/Strings+FOSDEM.swift",
    "Derived/Sources/Bundle+FOSDEM.swift",
  ],
  scripts: [swiftFormat],
  dependencies: [.package(product: "GRDB")]
)

let project = Project(
  name: "FOSDEM",
  organizationName: "com.mttcrsp.fosdem",
  options: .options(automaticSchemesOptions: .enabled(codeCoverageEnabled: true)),
  packages: [grdb, needle, ribs, rxSwift, snapshotTesting],
  settings: .settings(base: ["SWIFT_TREAT_WARNINGS_AS_ERRORS": "YES"]),
  targets: [app, appTests, appUITests, appSnapshotTests, dbGenerator]
)
