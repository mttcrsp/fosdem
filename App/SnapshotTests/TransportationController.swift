@testable
import Fosdem
import SnapshotTesting
import XCTest

final class TransportationControllerTests: XCTestCase {
  struct Dependencies: TransportationController.Dependencies {
    var navigationService: NavigationServiceProtocol = NavigationServiceProtocolMock()
    var openService: OpenServiceProtocol = OpenServiceProtocolMock()
  }

  func testAppearance() {
    let transportationController = TransportationController(dependencies: Dependencies())
    assertSnapshot(matching: transportationController, as: .image(on: .iPhone8Plus))
  }

  func testEvents() throws {
    var didError: NavigationService.ErrorHandler?
    let infoViewController = UIViewController()

    let openService = OpenServiceProtocolMock()
    openService.openHandler = { _, completion in completion?(true) }

    let navigationService = NavigationServiceProtocolMock()
    navigationService.makeInfoViewControllerHandler = { _, _, receivedDidError in
      didError = receivedDidError
      return infoViewController
    }

    var dependencies = Dependencies()
    dependencies.openService = openService
    dependencies.navigationService = navigationService

    let transportationController = TestTransportationController(dependencies: dependencies)
    assertSnapshot(matching: transportationController, as: .image(on: .iPhone8Plus))

    let transportationViewController = try XCTUnwrap(transportationController.viewControllers.first as? TransportationViewController)

    transportationController.transportationViewController(transportationViewController, didSelect: .appleMaps)
    XCTAssertEqual(openService.openCallCount, 1)
    XCTAssertEqual(openService.openArgValues.last?.absoluteString, "https://maps.apple.com/?address=Avenue%20Franklin%20Roosevelt%2050,%201050%20Brussels,%20Belgium&auid=2450730505287536200&ll=50.812050,4.382236&lsp=9902&q=Universit%C3%A9%20Libre%20de%20Bruxelles&_ext=ChgKBAgEEFcKBAgFEAMKBAgGEBkKBAgKEAESJCkjtQWwbFxJQDFgm0ZDufUQQDkZviUmcHNJQEGgZLl8GBkSQA%3D%3D")

    transportationController.transportationViewController(transportationViewController, didSelect: .googleMaps)
    XCTAssertEqual(openService.openCallCount, 2)
    XCTAssertEqual(openService.openArgValues.last?.absoluteString, "https://www.google.com/maps/place/Universit%C3%A9+Libre+de+Bruxelles/@50.8132068,4.3800335,17z/data=!3m1!4b1!4m5!3m4!1s0x47c3c4485d19ce43:0xe8eb9253c07c6691!8m2!3d50.8132068!4d4.3822222")

    transportationController.transportationViewController(transportationViewController, didSelect: .bus)
    XCTAssertEqual(navigationService.makeInfoViewControllerArgValues.map(\.0), ["By bus and/or tram"])
    XCTAssertEqual(navigationService.makeInfoViewControllerArgValues.map(\.1), [.bus])
    XCTAssertEqual(transportationController.showArgValues.map(\.0), [infoViewController])

    didError?(infoViewController, NSError(domain: "test", code: 1))

    XCTAssertEqual(transportationController.popViewControllerArgValues, [true])
  }
}

final class TestTransportationController: TransportationController {
  var showArgValues: [(UIViewController, Any?)] = []
  override func show(_ vc: UIViewController, sender: Any?) {
    super.show(vc, sender: sender)
    showArgValues = [(vc, sender)]
  }

  var popViewControllerArgValues: [Bool] = []
  override func popViewController(animated: Bool) -> UIViewController? {
    popViewControllerArgValues = [animated]
    return super.popViewController(animated: animated)
  }
}
