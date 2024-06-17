import Combine
@testable
import Fosdem
import XCTest

final class ApplicationViewModelTests: XCTestCase {
  func testDidLaunchAfterInstall() {
    let launchService = LaunchServiceProtocolMock()
    let dependencies = Dependencies(launchService: launchService)
    let viewModel = ApplicationViewModel(dependencies: dependencies)

    launchService.didLaunchAfterInstall = true
    XCTAssertTrue(viewModel.didLaunchAfterInstall)

    launchService.didLaunchAfterInstall = false
    XCTAssertFalse(viewModel.didLaunchAfterInstall)
  }

  func testCurrentYear() {
    let yearsService = YearsServiceProtocolMock()
    let dependencies = Dependencies(yearsService: yearsService)
    let viewModel = ApplicationViewModel(dependencies: dependencies)

    YearsServiceProtocolMock.current = 2016
    XCTAssertEqual(viewModel.currentYear, 2016)

    YearsServiceProtocolMock.current = 2024
    XCTAssertEqual(viewModel.currentYear, 2024)
  }

  func testDidLoad() {
    let favoritesService = FavoritesServiceProtocolMock()
    let scheduleService = ScheduleServiceProtocolMock()
    let ubiquitousPreferencesService = UbiquitousPreferencesServiceProtocolMock()
    let updateService = UpdateServiceProtocolMock()

    var dependencies = Dependencies()
    dependencies.favoritesService = favoritesService
    dependencies.scheduleService = scheduleService
    dependencies.ubiquitousPreferencesService = ubiquitousPreferencesService
    dependencies.updateService = updateService

    var handler: (() -> Void)?
    updateService.detectUpdatesHandler = { receivedHander in
      handler = receivedHander
    }

    let viewModel = ApplicationViewModel(dependencies: dependencies)
    viewModel.didLoad()

    XCTAssertEqual(ubiquitousPreferencesService.startMonitoringCallCount, 1)
    XCTAssertEqual(favoritesService.startMonitoringCallCount, 1)
    XCTAssertEqual(scheduleService.startUpdatingCallCount, 1)

    let expectation = expectation(description: "Did detect update")
    var cancellables: [AnyCancellable] = []
    var called = false
    viewModel.didDetectUpdate
      .sink { _ in called = true; expectation.fulfill() }
      .store(in: &cancellables)

    handler?()
    wait(for: [expectation])
    XCTAssertTrue(called)
  }

  func testApplicationDidBecomeActive() {
    let scheduleService = ScheduleServiceProtocolMock()
    let timeService = TimeServiceProtocolMock()

    var dependencies = Dependencies()
    dependencies.scheduleService = scheduleService
    dependencies.timeService = timeService

    let viewModel = ApplicationViewModel(dependencies: dependencies)
    viewModel.applicationDidBecomeActive()
    XCTAssertEqual(timeService.startMonitoringCallCount, 1)
    XCTAssertEqual(scheduleService.startUpdatingCallCount, 1)
  }

  func testApplicationWillResignActive() {
    let timeService = TimeServiceProtocolMock()
    let dependencies = Dependencies(timeService: timeService)
    let viewModel = ApplicationViewModel(dependencies: dependencies)
    viewModel.applicationWillResignActive()
    XCTAssertEqual(timeService.stopMonitoringCallCount, 1)
  }

  func testDidTapUpdate() throws {
    let url = try XCTUnwrap(URL(string: "https://itunes.apple.com/it/app/id1513719757"))

    let openService = OpenServiceProtocolMock()
    let dependencies = Dependencies(openService: openService)
    let viewModel = ApplicationViewModel(dependencies: dependencies)
    viewModel.didTapUpdate()
    XCTAssertEqual(openService.openArgValues, [url])
  }

  private struct Dependencies: ApplicationViewModel.Dependencies {
    var favoritesService: FavoritesServiceProtocol = FavoritesServiceProtocolMock()
    var launchService: LaunchServiceProtocol = LaunchServiceProtocolMock()
    var openService: OpenServiceProtocol = OpenServiceProtocolMock()
    var scheduleService: ScheduleServiceProtocol = ScheduleServiceProtocolMock()
    var timeService: TimeServiceProtocol = TimeServiceProtocolMock()
    var ubiquitousPreferencesService: UbiquitousPreferencesServiceProtocol = UbiquitousPreferencesServiceProtocolMock()
    var updateService: UpdateServiceProtocol = UpdateServiceProtocolMock()
    var yearsService: YearsServiceProtocol = YearsServiceProtocolMock()
  }
}
