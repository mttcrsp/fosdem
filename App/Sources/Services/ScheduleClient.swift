import Foundation

struct ScheduleClient {
  var startUpdating: () -> Void
  var stopUpdating: () -> Void

  #if DEBUG
  var disable: () -> Void
  #endif
}

extension ScheduleClient {
  init(fosdemYear: Int = 2023, networkClient: ScheduleClientNetwork, persistenceClient: ScheduleClientPersistence, defaults: ScheduleClientDefaults = UserDefaults.standard, timeInterval: TimeInterval = 60 * 60) {
    #if DEBUG
    var isEnabled = true
    disable = { isEnabled = false }
    #endif

    var timer: Timer?
    var isUpdating = false

    var latestUpdate: Date {
      get { defaults.latestScheduleUpdate ?? .distantPast }
      set { defaults.latestScheduleUpdate = newValue }
    }

    func performUpdate() {
      let shouldPerformUpdate = abs(latestUpdate.timeIntervalSinceNow) >= timeInterval
      guard shouldPerformUpdate, !isUpdating else { return }
      isUpdating = true

      _ = networkClient.getSchedule(fosdemYear) { result in
        guard case let .success(schedule) = result else { return }

        #if DEBUG
        guard isEnabled else { return }
        #endif

        persistenceClient.upsertSchedule(schedule) { error in
          assert(error == nil)
          isUpdating = false
          latestUpdate = Date()
        }
      }
    }

    startUpdating = {
      performUpdate()
      timer = timer ?? .scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
        performUpdate()
      }
    }

    stopUpdating = {
      timer?.invalidate()
      timer = nil
    }
  }
}

private extension ScheduleClientDefaults {
  var latestScheduleUpdate: Date? {
    get { value(forKey: .latestScheduleUpdateKey) as? Date }
    set { set(newValue, forKey: .latestScheduleUpdateKey) }
  }
}

private extension String {
  static var latestScheduleUpdateKey: String { #function }
}

/// @mockable
protocol ScheduleClientProtocol {
  var startUpdating: () -> Void { get }
  var stopUpdating: () -> Void { get }

  #if DEBUG
  var disable: () -> Void { get }
  #endif
}

extension ScheduleClient: ScheduleClientProtocol {}

/// @mockable
protocol ScheduleClientDefaults: AnyObject {
  func value(forKey key: String) -> Any?
  func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: ScheduleClientDefaults {}

/// @mockable
protocol ScheduleClientNetwork {
  var getSchedule: (Year, @escaping (Result<Schedule, Error>) -> Void) -> NetworkClientTask { get }
}

extension NetworkClient: ScheduleClientNetwork {}

/// @mockable
protocol ScheduleClientPersistence {
  var upsertSchedule: (Schedule, @escaping (Error?) -> Void) -> Void { get }
}

extension PersistenceClient: ScheduleClientPersistence {}

protocol HasScheduleClient {
  var scheduleClient: ScheduleClientProtocol { get }
}
