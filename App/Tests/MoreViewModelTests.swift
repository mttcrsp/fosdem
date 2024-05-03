import Combine
@testable
import Fosdem
import XCTest

final class MoreViewModelTests: XCTestCase {
  private let acknowledgement = Acknowledgement(name: "acknowledgement", url: URL(string: "https://fosdem.org")!)

  func testDidSelectAcknowledgements() throws {
    let acknowledgementsService = AcknowledgementsServiceProtocolMock()
    let dependencies = Dependencies(acknowledgementsService: acknowledgementsService)
    let viewModel = MoreViewModel(dependencies: dependencies)

    XCTContext.runActivity(named: "Failure") { activity in
      let error = NSError(domain: "test", code: 1)
      acknowledgementsService.loadAcknowledgementsHandler = { throw error }

      var result: Result<[Acknowledgement], Error>?
      var cancellables: [AnyCancellable] = []
      let expectation = expectation(description: activity.name)
      viewModel.didLoadAcknowledgements
        .sink { receivedResult in result = receivedResult; expectation.fulfill() }
        .store(in: &cancellables)

      viewModel.didSelectAcknowledgements()
      wait(for: [expectation])

      if case let .failure(receivedError) = result {
        XCTAssertEqual(receivedError as NSError, error)
      } else {
        XCTFail("Unexpectedly succeeded in loading acknowledgements")
      }
    }

    try XCTContext.runActivity(named: "Success") { activity in
      acknowledgementsService.loadAcknowledgementsHandler = { [unowned self] in
        [acknowledgement]
      }

      var result: Result<[Acknowledgement], Error>?
      var cancellables: [AnyCancellable] = []
      let expectation = expectation(description: activity.name)
      viewModel.didLoadAcknowledgements
        .sink { receivedResult in result = receivedResult; expectation.fulfill() }
        .store(in: &cancellables)

      viewModel.didSelectAcknowledgements()
      wait(for: [expectation])
      XCTAssertEqual(try result?.get(), [acknowledgement])
    }

    try XCTContext.runActivity(named: "Cache") { activity in
      acknowledgementsService.loadAcknowledgementsHandler = {
        throw NSError(domain: "test", code: 1)
      }

      var result: Result<[Acknowledgement], Error>?
      var cancellables: [AnyCancellable] = []
      let expectation = expectation(description: activity.name)
      viewModel.didLoadAcknowledgements
        .sink { receivedResult in result = receivedResult; expectation.fulfill() }
        .store(in: &cancellables)

      viewModel.didSelectAcknowledgements()
      wait(for: [expectation])
      XCTAssertEqual(try result?.get(), [acknowledgement])
    }
  }

  func testDidSelectAcknowledgement() throws {
    var completion: ((Bool) -> Void)?
    let openService = OpenServiceProtocolMock()
    openService.openHandler = { _, receivedCompletion in
      completion = receivedCompletion
    }

    let dependencies = Dependencies(openService: openService)
    let viewModel = MoreViewModel(dependencies: dependencies)
    viewModel.didSelectAcknowledgement(acknowledgement)
    XCTAssertEqual(openService.openArgValues, [acknowledgement.url])

    var cancellables: [AnyCancellable] = []
    let expectation = expectation(description: "Did open acknowledgement")
    viewModel.didOpenAcknowledgement
      .sink { _ in expectation.fulfill() }
      .store(in: &cancellables)
    completion?(true)
    wait(for: [expectation])
  }

  func testDidSelectCode() throws {
    let url = try XCTUnwrap(URL(string: "https://www.github.com/mttcrsp/fosdem"))

    var completion: ((Bool) -> Void)?
    let openService = OpenServiceProtocolMock()
    openService.openHandler = { _, receivedCompletion in
      completion = receivedCompletion
    }

    let dependencies = Dependencies(openService: openService)
    let viewModel = MoreViewModel(dependencies: dependencies)
    viewModel.didSelectCode()
    XCTAssertEqual(openService.openArgValues, [url])

    var cancellables: [AnyCancellable] = []
    let expectation = expectation(description: "Did open url")
    viewModel.didOpenURL
      .sink { _ in expectation.fulfill() }
      .store(in: &cancellables)
    completion?(true)
    wait(for: [expectation])
  }

  func testDidSelectItem() throws {
    var completion: ((Result<NSAttributedString, Error>) -> Void)?
    let infoService = InfoServiceProtocolMock()
    infoService.loadAttributedTextHandler = { _, receivedCompletion in
      completion = receivedCompletion
    }

    let dependencies = Dependencies(infoService: infoService)
    let viewModel = MoreViewModel(dependencies: dependencies)

    XCTContext.runActivity(named: "Failure") { activity in
      var result: Result<(Info, MoreItem, NSAttributedString), Error>?
      var cancellables: [AnyCancellable] = []
      let expectation = expectation(description: activity.name)
      viewModel.didLoadInfo
        .sink { receivedResult in result = receivedResult; expectation.fulfill() }
        .store(in: &cancellables)

      viewModel.didSelectItem(.legal)

      let error = NSError(domain: "test", code: 1)
      completion?(.failure(error))
      wait(for: [expectation])

      if case let .failure(receivedError) = result {
        XCTAssertEqual(receivedError as NSError, error)
      } else {
        XCTFail("Unexpectedly succeeded in loading info")
      }
    }

    try XCTContext.runActivity(named: "Success") { activity in
      var result: Result<(Info, MoreItem, NSAttributedString), Error>?
      var cancellables: [AnyCancellable] = []
      let expectation = expectation(description: activity.name)
      viewModel.didLoadInfo
        .sink { receivedResult in result = receivedResult; expectation.fulfill() }
        .store(in: &cancellables)

      let item = MoreItem.legal
      viewModel.didSelectItem(item)

      let attributedString = NSAttributedString()
      completion?(.success(attributedString))
      wait(for: [expectation])

      let values = try result?.get()
      XCTAssertEqual(values?.0, item.info)
      XCTAssertEqual(values?.1, item)
      XCTAssertIdentical(values?.2, attributedString)
    }
  }

  private struct Dependencies: MoreViewModel.Dependencies {
    var acknowledgementsService: AcknowledgementsServiceProtocol = AcknowledgementsServiceProtocolMock()
    var infoService: InfoServiceProtocol = InfoServiceProtocolMock()
    var openService: OpenServiceProtocol = OpenServiceProtocolMock()
    var yearsService: YearsServiceProtocol = YearsServiceProtocolMock()
  }
}
