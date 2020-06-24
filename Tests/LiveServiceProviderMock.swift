@testable
import Fosdem
import Foundation

final class LiveServiceProviderMock: LiveServiceProvider {
  private(set) var block: ((LiveServiceTimer) -> Void)?
  private(set) var interval: TimeInterval?
  private(set) var repeats: Bool?
  private let timer: LiveServiceTimerMock

  init(timer: LiveServiceTimerMock) {
    self.timer = timer
    self.timer.provider = self
  }

  func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (LiveServiceTimer) -> Void) -> LiveServiceTimer {
    self.interval = interval
    self.repeats = repeats
    self.block = block
    return timer
  }

  func remove(_ timer: LiveServiceTimerMock) {
    if timer === self.timer {
      interval = nil
      repeats = nil
      block = nil
    }
  }
}
