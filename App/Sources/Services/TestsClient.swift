// #if DEBUG
// import UIKit
//
// final class TestsClient {
//  private let preInitCommands: [PreInitCommand.Type] = [
//    ResetDefaults.self,
//    PreventOnboarding.self,
//    SpeedUpAnimations.self,
//  ]
//
//  private let postInitCommands: [PostInitCommand.Type] = [
//    OverrideDate.self,
//    OverrideDates.self,
//    OverrideTimeClientInterval.self,
//    OverrideVideo.self,
//    PreventScheduleUpdates.self,
//    SetFavoriteEvents.self,
//    SetFavoriteTracks.self,
//  ]
//
//  private let environment: [String: String]
//
//  init(environment: [String: String] = ProcessInfo.processInfo.environment) {
//    self.environment = environment
//  }
//
//  func runPreInitializationTestCommands() {
//    for command in preInitCommands {
//      command.perform(with: environment)
//    }
//  }
//
//  func runPostInitializationTestCommands(with clients: Clients) {
//    for command in postInitCommands {
//      command.perform(with: clients, environment: environment)
//    }
//  }
// }
//
// private protocol PreInitCommand {
//  static func perform(with environment: [String: String])
// }
//
// private protocol PostInitCommand {
//  static func perform(with clients: Clients, environment: [String: String])
// }
//
// private struct ResetDefaults: PreInitCommand {
//  static func perform(with environment: [String: String]) {
//    guard let name = Bundle.main.bundleIdentifier, environment["RESET_DEFAULTS"] != nil else { return }
//    let defaults = UserDefaults.standard
//    defaults.removePersistentDomain(forName: name)
//  }
// }
//
// private struct PreventOnboarding: PreInitCommand {
//  static func perform(with environment: [String: String]) {
//    guard environment["ENABLE_ONBOARDING"] == nil else { return }
//    let defaults = UserDefaults.standard
//    defaults.set(YearsClient.current, forKey: LaunchClient.latestFosdemYearKey)
//    defaults.set(Bundle.main.bundleShortVersion, forKey: LaunchClient.latestBundleShortVersionKey)
//  }
// }
//
// private struct SpeedUpAnimations: PreInitCommand {
//  static func perform(with _: [String: String]) {
//    for window in UIApplication.shared.windows {
//      window.layer.speed = 100
//    }
//  }
// }
//
// private struct PreventScheduleUpdates: PostInitCommand {
//  static func perform(with clients: Clients, environment: [String: String]) {
//    guard environment["ENABLE_SCHEDULE_UPDATES"] == nil else { return }
//    clients.scheduleClient.disable()
//  }
// }
//
// private struct SetFavoriteEvents: PostInitCommand {
//  static func perform(with clients: Clients, environment: [String: String]) {
//    guard let value = environment["SET_FAVORITE_EVENTS"] else { return }
//    let identifiers = Set(value.components(separatedBy: ",").compactMap(Int.init))
//    clients.favoritesClient.setEventsIdentifiers(identifiers)
//  }
// }
//
// private struct SetFavoriteTracks: PostInitCommand {
//  static func perform(with clients: Clients, environment: [String: String]) {
//    guard let value = environment["SET_FAVORITE_TRACKS"] else { return }
//    let identifiers = Set(value.components(separatedBy: ","))
//    clients.favoritesClient.setTracksIdentifiers(identifiers)
//  }
// }
//
// private struct OverrideTimeClientInterval: PostInitCommand {
//  static func perform(with clients: Clients, environment: [String: String]) {
//    guard let value = environment["OVERRIDE_TIME_SERVICE_INTERVAL"], let interval = TimeInterval(value) else { return }
//    clients.timeClient = TimeClient(timeInterval: interval)
//  }
// }
//
// private struct OverrideDate: PostInitCommand {
//  static func perform(with clients: Clients, environment: [String: String]) {
//    guard let value = environment["OVERRIDE_NOW"], let interval = Double(value) else { return }
//    clients.timeClient.now = { Date(timeIntervalSince1970: interval) }
//  }
// }
//
// private struct OverrideDates: PostInitCommand {
//  private static var timer: Timer?
//
//  static func perform(with clients: Clients, environment: [String: String]) {
//    guard let value = environment["OVERRIDE_NOWS"] else { return }
//    let components = value.components(separatedBy: ",")
//
//    guard components.count == 2, let value1 = Double(components[0]), let value2 = Double(components[1]) else { return }
//    let date1 = Date(timeIntervalSince1970: value1)
//    let date2 = Date(timeIntervalSince1970: value2)
//
//    var flag = true
//    timer = .scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
//      clients.timeClient.now = { flag ? date1 : date2 }
//      flag.toggle()
//    }
//  }
// }
//
// private struct OverrideVideo: PostInitCommand {
//  static func perform(with clients: Clients, environment: [String: String]) {
//    guard let value = environment["OVERRIDE_VIDEO"], let video = Data(base64Encoded: value) else { return }
//
//    do {
//      let directory = FileManager.default.temporaryDirectory
//      let url = directory.appendingPathComponent("test.mp4")
//      try video.write(to: url)
//
//      let links = [Link(name: "test", url: url)]
//      clients.persistenceClient.updateLinksForEvent(11717, links) { error in
//        assert(error == nil)
//      }
//    } catch {
//      assertionFailure(error.localizedDescription)
//    }
//  }
// }
//
// private extension FavoritesClientProtocol {
//  func setTracksIdentifiers(_ newTracksIdentifiers: Set<String>) {
//    for identifier in tracksIdentifiers() {
//      removeTrack(identifier)
//    }
//
//    for identifier in newTracksIdentifiers {
//      addTrack(identifier)
//    }
//  }
//
//  func setEventsIdentifiers(_ newEventsIdentifiers: Set<Int>) {
//    for identifier in eventsIdentifiers() {
//      removeEvent(identifier)
//    }
//
//    for identifier in newEventsIdentifiers {
//      addEvent(identifier)
//    }
//  }
// }
// #endif
