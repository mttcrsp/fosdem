import Dispatch

final class SchedulerService {
  func onMainQueue(_ work: @escaping () -> Void) {
    DispatchQueue.main.async(execute: work)
  }
}

/// @mockable
protocol SchedulerServiceProtocol {
  func onMainQueue(_ work: @escaping () -> Void)
}

extension SchedulerService: SchedulerServiceProtocol {}
