import Foundation

final class LiveService {
  private var timer: LiveServiceTimer?

  private let notificationCenter = NotificationCenter()
  private let timerProvider: LiveServiceProvider
  private let timeInterval: TimeInterval

  init(timeInterval: TimeInterval = 10, timerProvider: LiveServiceProvider = LiveServiceTimerProvider()) {
    self.timerProvider = timerProvider
    self.timeInterval = timeInterval
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

  private func timerDidFire() {
    notificationCenter.post(Notification(name: .timeDidChange))
  }
}

private final class LiveServiceTimerProvider: LiveServiceProvider {
  func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (LiveServiceTimer) -> Void) -> LiveServiceTimer {
    Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats, block: block)
  }
}

extension Timer: LiveServiceTimer {}

private extension Notification.Name {
  static var timeDidChange: Notification.Name { Notification.Name(#function) }
}

/// @mockable
protocol LiveServiceProtocol {
  func startMonitoring()
  func stopMonitoring()
  func addObserver(_ handler: @escaping () -> Void) -> NSObjectProtocol
}

extension LiveService: LiveServiceProtocol {}

/// @mockable
protocol LiveServiceTimer {
  func invalidate()
}

/// @mockable
protocol LiveServiceProvider {
  func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (LiveServiceTimer) -> Void) -> LiveServiceTimer
}
