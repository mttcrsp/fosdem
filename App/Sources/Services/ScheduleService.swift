import Foundation

struct ScheduleService {
  var startUpdating: () -> Void
  var stopUpdating: () -> Void

  #if DEBUG
  var disable: () -> Void
  #endif
}

extension ScheduleService {
  init(fosdemYear: Int = 2023, networkService: ScheduleServiceNetwork, persistenceService: ScheduleServicePersistence, defaults: ScheduleServiceDefaults = UserDefaults.standard, timeInterval: TimeInterval = 60 * 60) {
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

      let request = ScheduleRequest(year: fosdemYear)
      networkService.perform(request) { result in
        guard case let .success(schedule) = result else { return }

        #if DEBUG
        guard isEnabled else { return }
        #endif

        persistenceService.upsertSchedule(schedule) { error in
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

private extension ScheduleServiceDefaults {
  var latestScheduleUpdate: Date? {
    get { value(forKey: .latestScheduleUpdateKey) as? Date }
    set { set(newValue, forKey: .latestScheduleUpdateKey) }
  }
}

private extension String {
  static var latestScheduleUpdateKey: String { #function }
}

/// @mockable
protocol ScheduleServiceProtocol {
  var startUpdating: () -> Void { get }
  var stopUpdating: () -> Void { get }

  #if DEBUG
  var disable: () -> Void { get }
  #endif
}

extension ScheduleService: ScheduleServiceProtocol {}

/// @mockable
protocol ScheduleServiceDefaults: AnyObject {
  func value(forKey key: String) -> Any?
  func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: ScheduleServiceDefaults {}

/// @mockable
protocol ScheduleServiceNetwork {
  @discardableResult
  func perform(_ request: ScheduleRequest, completion: @escaping (Result<Schedule, Error>) -> Void) -> NetworkServiceTask
}

extension NetworkService: ScheduleServiceNetwork {}

/// @mockable
protocol ScheduleServicePersistence {
  var upsertSchedule: (Schedule, @escaping (Error?) -> Void) -> Void { get }
}

extension PersistenceService: ScheduleServicePersistence {}

protocol HasScheduleService {
  var scheduleService: ScheduleServiceProtocol { get }
}
