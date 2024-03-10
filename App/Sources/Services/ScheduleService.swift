import Foundation

final class ScheduleService {
  #if DEBUG
  private var isEnabled = true
  #endif

  private var timer: Timer?
  private var isUpdating = false

  private let fosdemYear: Int
  private let timeInterval: TimeInterval
  private let defaults: ScheduleServiceDefaults
  private let networkService: ScheduleServiceNetwork
  private let persistenceService: ScheduleServicePersistence

  init(fosdemYear: Int, networkService: ScheduleServiceNetwork, persistenceService: ScheduleServicePersistence, defaults: ScheduleServiceDefaults = UserDefaults.standard, timeInterval: TimeInterval = 60 * 60) {
    self.defaults = defaults
    self.fosdemYear = fosdemYear
    self.timeInterval = timeInterval
    self.networkService = networkService
    self.persistenceService = persistenceService
  }

  deinit {
    timer?.invalidate()
  }

  func startUpdating() {
    performUpdate()
    timer = timer ?? .scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak self] _ in
      self?.performUpdate()
    }
  }

  func stopUpdating() {
    timer?.invalidate()
    timer = nil
  }

  private var latestUpdate: Date {
    get { defaults.latestScheduleUpdate ?? .distantPast }
    set { defaults.latestScheduleUpdate = newValue }
  }

  private var shouldPerformUpdate: Bool {
    abs(latestUpdate.timeIntervalSinceNow) >= timeInterval
  }

  private func performUpdate() {
    guard shouldPerformUpdate, !isUpdating else { return }
    isUpdating = true

    let request = ScheduleRequest(year: fosdemYear)
    networkService.perform(request) { [weak self] result in
      guard case let .success(schedule) = result, let self else { return }

      #if DEBUG
      guard isEnabled else { return }
      #endif

      let operation = UpsertSchedule(schedule: schedule)
      persistenceService.performWrite(operation) { [weak self] error in

        assert(error == nil)
        self?.isUpdating = false
        self?.latestUpdate = Date()
      }
    }
  }

  #if DEBUG
  func disable() {
    isEnabled = false
  }
  #endif
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
  func startUpdating()
  func stopUpdating()

  #if DEBUG
  func disable()
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
  func performWrite(_ write: PersistenceServiceWrite, completion: @escaping (Error?) -> Void)
}

extension PersistenceService: ScheduleServicePersistence {}

protocol HasScheduleService {
  var scheduleService: ScheduleServiceProtocol { get }
}
