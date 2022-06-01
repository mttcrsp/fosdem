import Foundation

final class TimeService {
  private var timer: TimeServiceTimer?

  #if DEBUG
  var now: Date
  #else
  var now: Date { Date() }
  #endif

  private let notificationCenter = NotificationCenter()
  private let timerProvider: TimeServiceProvider
  private let timeInterval: TimeInterval

  init(timeInterval: TimeInterval = 10, timerProvider: TimeServiceProvider = TimeServiceTimerProvider()) {
    self.timerProvider = timerProvider
    self.timeInterval = timeInterval

    #if DEBUG
    let calendar = Calendar.autoupdatingCurrent
    let timeZone = TimeZone(identifier: "Europe/Brussels")
    let components = DateComponents(timeZone: timeZone, year: 2022, month: 2, day: 6, hour: 12, minute: 45)
    now = calendar.date(from: components) ?? Date()
    #endif
  }

  deinit {
    timer?.invalidate()
  }

  func startMonitoring() {
    timer = timerProvider.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak self] _ in
      self?.timerDidFire()
    }
  }

  func stopMonitoring() {
    timer?.invalidate()
    timer = nil
  }

  func addObserver(_ handler: @escaping () -> Void) -> NSObjectProtocol {
    notificationCenter.addObserver(forName: .timeDidChange, object: nil, queue: nil, using: { _ in handler() })
  }

  func removeObserver(_ observer: NSObjectProtocol) {
    notificationCenter.removeObserver(observer)
  }

  private func timerDidFire() {
    notificationCenter.post(Notification(name: .timeDidChange))
  }
}

private final class TimeServiceTimerProvider: TimeServiceProvider {
  func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (TimeServiceTimer) -> Void) -> TimeServiceTimer {
    Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats, block: block)
  }
}

extension Timer: TimeServiceTimer {}

private extension Notification.Name {
  static var timeDidChange: Notification.Name { Notification.Name(#function) }
}

/// @mockable
protocol TimeServiceProtocol: AnyObject {
  #if DEBUG
  var now: Date { get set }
  #else
  var now: Date { get }
  #endif

  func startMonitoring()
  func stopMonitoring()
  func addObserver(_ handler: @escaping () -> Void) -> NSObjectProtocol
  func removeObserver(_ observer: NSObjectProtocol)
}

extension TimeService: TimeServiceProtocol {}

/// @mockable
protocol TimeServiceTimer {
  func invalidate()
}

/// @mockable
protocol TimeServiceProvider {
  func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (TimeServiceTimer) -> Void) -> TimeServiceTimer
}
