import Foundation

protocol LiveServiceProvider {
  func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer
}

final class LiveService {
  private var timer: Timer?

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
  func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
    .scheduledTimer(withTimeInterval: interval, repeats: repeats, block: block)
  }
}

private extension Notification.Name {
  static var timeDidChange: Notification.Name { Notification.Name(#function) }
}
