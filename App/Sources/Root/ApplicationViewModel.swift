import Combine
import Foundation

final class ApplicationViewModel {
  typealias Dependencies = HasFavoritesService & HasLaunchService & HasOpenService & HasScheduleService & HasTimeService & HasUbiquitousPreferencesService & HasUpdateService & HasYearsService

  let didDetectUpdate = PassthroughSubject<Void, Never>()
  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
  }

  var didLaunchAfterInstall: Bool {
    dependencies.launchService.didLaunchAfterInstall
  }

  var currentYear: Year {
    type(of: dependencies.yearsService).current
  }

  func didLoad() {
    dependencies.ubiquitousPreferencesService.startMonitoring()
    dependencies.favoritesService.startMonitoring()
    dependencies.scheduleService.startUpdating()
    dependencies.updateService.detectUpdates { [weak self] in
      self?.didDetectUpdate.send()
    }
  }

  func applicationDidBecomeActive() {
    dependencies.timeService.startMonitoring()
    dependencies.scheduleService.startUpdating()
  }

  func applicationWillResignActive() {
    dependencies.timeService.stopMonitoring()
  }

  func didTapUpdate() {
    if let url = URL.fosdemAppStore {
      dependencies.openService.open(url, completion: nil)
    }
  }
}
