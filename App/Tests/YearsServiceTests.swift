@testable
import Fosdem
import XCTest

final class YearsServiceTests: XCTestCase {
  func testIsYearDownloaded() {
    let fileManager = YearsServiceFileMock()
    fileManager.urlsHandler = { _, _ in [URL(fileURLWithPath: "test")] }
    fileManager.fileExistsHandler = { _ in true }

    let networkService = YearsServiceNetworkMock()
    let service = YearsService(networkService: networkService, fileManager: fileManager)

    XCTAssertTrue(service.isYearDownloaded(2021))
    XCTAssertEqual(fileManager.urlsArgValues.map(\.0), [.documentDirectory])
    XCTAssertEqual(fileManager.urlsArgValues.map(\.1), [.userDomainMask])
    XCTAssertEqual(fileManager.fileExistsArgValues, ["/test/2021.sqlite"])
  }

  func testIsYearDownloadedMissingDocuments() {
    let fileManager = YearsServiceFileMock()
    fileManager.urlsHandler = { _, _ in [] }

    let networkService = YearsServiceNetworkMock()
    let service = YearsService(networkService: networkService, fileManager: fileManager)

    XCTAssertFalse(service.isYearDownloaded(2021))
  }

  func testIsYearDownloadedNoFile() {
    let fileManager = YearsServiceFileMock()
    fileManager.urlsHandler = { _, _ in [URL(fileURLWithPath: "test")] }
    fileManager.fileExistsHandler = { _ in false }

    let networkService = YearsServiceNetworkMock()
    let service = YearsService(networkService: networkService, fileManager: fileManager)

    XCTAssertFalse(service.isYearDownloaded(2021))
  }

  func testDownloadYear() {
    let networkServiceTask = NetworkServiceTaskMock()
    let networkService = YearsServiceNetworkMock()
    networkService.performHandler = { _, completion in
      completion(.success(self.makeSchedule()))
      return networkServiceTask
    }

    let fileManager = YearsServiceFileMock()
    fileManager.urlsHandler = { _, _ in [URL(fileURLWithPath: "test")] }

    let yearPersistenceService = PersistenceServiceProtocolMock()
    yearPersistenceService.performWriteHandler = { _, completion in
      completion(nil)
    }

    let persistenceServiceBuilder = YearsServicePersistenceBuilderMock()
    persistenceServiceBuilder.makePersistenceServiceHandler = { _ in
      yearPersistenceService
    }

    let service = YearsService(
      networkService: networkService,
      persistenceServiceBuilder: persistenceServiceBuilder,
      fileManager: fileManager
    )

    let expectation = self.expectation(description: #function)
    let task = service.downloadYear(2021) { error in
      XCTAssertNil(error)
      expectation.fulfill()
    }
    waitForExpectations(timeout: 1)

    XCTAssertTrue(task as? NetworkServiceTaskMock === networkServiceTask)
    XCTAssertEqual(networkService.performCallCount, 1)
    XCTAssertEqual(networkService.performArgValues.first?.url.absoluteString, "https://fosdem.org/2021/schedule/xml")
    XCTAssertEqual(fileManager.urlsArgValues.map(\.0), [.documentDirectory, .documentDirectory, .documentDirectory])
    XCTAssertEqual(fileManager.urlsArgValues.map(\.1), [.userDomainMask, .userDomainMask, .userDomainMask])
    XCTAssertEqual(fileManager.createDirectoryArgValues.map(\.0), [URL(fileURLWithPath: "test/years")])
    XCTAssertEqual(fileManager.createDirectoryArgValues.map(\.1), [true])
    XCTAssertEqual(fileManager.createFileArgValues.map(\.0), ["/test/2021.sqlite"])
    XCTAssertEqual(fileManager.createFileArgValues.map(\.1), [nil])
    XCTAssertTrue(yearPersistenceService.performWriteArgValues.first is UpsertSchedule)
  }

  func testDownloadYearNetworkError() {
    let error = NSError(domain: "test", code: 1)

    let networkServiceTask = NetworkServiceTaskMock()
    let networkService = YearsServiceNetworkMock()
    networkService.performHandler = { _, completion in
      completion(.failure(error))
      return networkServiceTask
    }

    let fileManager = YearsServiceFileMock()
    let persistenceServiceBuilder = YearsServicePersistenceBuilderMock()

    let service = YearsService(
      networkService: networkService,
      persistenceServiceBuilder: persistenceServiceBuilder,
      fileManager: fileManager
    )

    let expectation = self.expectation(description: #function)
    _ = service.downloadYear(2021) { receivedError in
      XCTAssertEqual(error, receivedError as NSError?)
      expectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testDownloadYearDocumentsDirectoryError() {
    let networkServiceTask = NetworkServiceTaskMock()
    let networkService = YearsServiceNetworkMock()
    networkService.performHandler = { _, completion in
      completion(.success(self.makeSchedule()))
      return networkServiceTask
    }

    let fileManager = YearsServiceFileMock()
    fileManager.urlsHandler = { _, _ in [] }

    let persistenceServiceBuilder = YearsServicePersistenceBuilderMock()

    let service = YearsService(
      networkService: networkService,
      persistenceServiceBuilder: persistenceServiceBuilder,
      fileManager: fileManager
    )

    let expectation = self.expectation(description: #function)
    _ = service.downloadYear(2021) { error in
      let error1 = error as NSError?
      let error2 = YearsService.Error.documentDirectoryNotFound as NSError?
      XCTAssertEqual(error1, error2)
      expectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testDownloadYearCreateDirectoryError() {
    let error = NSError(domain: "test", code: 1)

    let networkServiceTask = NetworkServiceTaskMock()
    let networkService = YearsServiceNetworkMock()
    networkService.performHandler = { _, completion in
      completion(.success(self.makeSchedule()))
      return networkServiceTask
    }

    let fileManager = YearsServiceFileMock()
    fileManager.urlsHandler = { _, _ in [URL(fileURLWithPath: "test")] }
    fileManager.createDirectoryHandler = { _, _, _ in throw error }

    let persistenceServiceBuilder = YearsServicePersistenceBuilderMock()

    let service = YearsService(
      networkService: networkService,
      persistenceServiceBuilder: persistenceServiceBuilder,
      fileManager: fileManager
    )

    let expectation = self.expectation(description: #function)
    _ = service.downloadYear(2021) { receivedError in
      XCTAssertEqual(error, receivedError as NSError?)
      expectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testDownloadYearMakePersistenceServiceError() {
    let error = NSError(domain: "test", code: 1)

    let networkServiceTask = NetworkServiceTaskMock()
    let networkService = YearsServiceNetworkMock()
    networkService.performHandler = { _, completion in
      completion(.success(self.makeSchedule()))
      return networkServiceTask
    }

    let fileManager = YearsServiceFileMock()
    fileManager.urlsHandler = { _, _ in [URL(fileURLWithPath: "test")] }

    let persistenceServiceBuilder = YearsServicePersistenceBuilderMock()
    persistenceServiceBuilder.makePersistenceServiceHandler = { _ in throw error }

    let service = YearsService(
      networkService: networkService,
      persistenceServiceBuilder: persistenceServiceBuilder,
      fileManager: fileManager
    )

    let expectation = self.expectation(description: #function)
    _ = service.downloadYear(2021) { receivedError in
      XCTAssertEqual(error, receivedError as NSError?)
      expectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testDownloadYearPerformWriteError() {
    let error = NSError(domain: "test", code: 1)

    let networkServiceTask = NetworkServiceTaskMock()
    let networkService = YearsServiceNetworkMock()
    networkService.performHandler = { _, completion in
      completion(.success(self.makeSchedule()))
      return networkServiceTask
    }

    let fileManager = YearsServiceFileMock()
    fileManager.urlsHandler = { _, _ in [URL(fileURLWithPath: "test")] }

    let persistenceServiceBuilder = YearsServicePersistenceBuilderMock()
    persistenceServiceBuilder.makePersistenceServiceHandler = { _ in
      let persistenceService = PersistenceServiceProtocolMock()
      persistenceService.performWriteHandler = { _, completion in completion(error) }
      return persistenceService
    }

    let service = YearsService(
      networkService: networkService,
      persistenceServiceBuilder: persistenceServiceBuilder,
      fileManager: fileManager
    )

    let expectation = self.expectation(description: #function)
    _ = service.downloadYear(2021) { receivedError in
      XCTAssertEqual(error, receivedError as NSError?)
      expectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  private func makeSchedule() -> Schedule {
    .init(conference: Conference(title: "", subtitle: nil, venue: "", city: "", start: .init(), end: .init()), days: [])
  }
}
