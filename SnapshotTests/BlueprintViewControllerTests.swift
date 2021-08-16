@testable
import Fosdem
import SnapshotTesting
import XCTest

final class BlueprintViewControllerTests: XCTestCase {
  func testBlueprintsFullscreen() throws {
    let building = try makeBuilding()

    let blueprintsViewController = BlueprintsViewController(style: .fullscreen)
    let blueprintsNavigationController = UINavigationController(rootViewController: blueprintsViewController)
    blueprintsViewController.building = nil
    assertSnapshot(matching: blueprintsNavigationController, as: .image(on: .iPhone8Plus))

    blueprintsViewController.building = try makeNoBlueprintsBuilding()
    assertSnapshot(matching: blueprintsNavigationController, as: .image(on: .iPhone8Plus))
    XCTAssertNil(blueprintsViewController.visibleBlueprint)

    blueprintsViewController.building = building
    assertSnapshot(matching: blueprintsNavigationController, as: .image(on: .iPhone8Plus))
    XCTAssertEqual(blueprintsViewController.visibleBlueprint, building.blueprints[0])

    blueprintsViewController.setVisibleBlueprint(building.blueprints[1], animated: false)
    assertSnapshot(matching: blueprintsNavigationController, as: .image(on: .iPhone8Plus))
    XCTAssertEqual(blueprintsViewController.visibleBlueprint, building.blueprints[1])

    let delegate = BlueprintsViewControllerDelegateMock()
    blueprintsViewController.blueprintsDelegate = delegate

    let dismissButton = blueprintsViewController.navigationItem.rightBarButtonItem
    let dismissTarget = try XCTUnwrap(dismissButton?.target as? NSObject)
    let dismissAction = try XCTUnwrap(dismissButton?.action)
    dismissTarget.perform(dismissAction)
    XCTAssertEqual(delegate.blueprintsViewControllerDidTapDismissCallCount, 1)
  }

  func testBlueprintsEmbedded() throws {
    let blueprintsViewController = BlueprintsViewController(style: .embedded)
    let blueprintsNavigationController = UINavigationController(rootViewController: blueprintsViewController)
    assertSnapshot(matching: blueprintsNavigationController, as: .image(on: .iPhone8Plus))

    blueprintsViewController.building = try makeNoBlueprintsBuilding()
    assertSnapshot(matching: blueprintsNavigationController, as: .image(on: .iPhone8Plus))

    blueprintsViewController.building = try makeBuilding()
    assertSnapshot(matching: blueprintsNavigationController, as: .image(on: .iPhone8Plus))

    let delegate = BlueprintsViewControllerDelegateMock()
    blueprintsViewController.blueprintsDelegate = delegate

    let dismissButton = blueprintsViewController.navigationItem.leftBarButtonItem
    let dismissTarget = try XCTUnwrap(dismissButton?.target as? NSObject)
    let dismissAction = try XCTUnwrap(dismissButton?.action)
    dismissTarget.perform(dismissAction)
    XCTAssertEqual(delegate.blueprintsViewControllerCallCount, 1)
  }

  func testBlueprintsSwiping() throws {
    let blueprintsViewController = BlueprintsViewController(style: .embedded)
    let blueprintsNavigationController = UINavigationController(rootViewController: blueprintsViewController)
    blueprintsViewController.building = try makeBuilding()

    let blueprintViewController1 = try XCTUnwrap(blueprintsViewController.viewControllers?.first as? EmbeddedBlueprintViewController)
    XCTAssertEqual(blueprintsViewController.viewControllers?.count, 1)
    XCTAssertEqual(blueprintsViewController.viewControllers?.count, 1)

    func after(_ viewController: UIViewController) -> EmbeddedBlueprintViewController? {
      blueprintsViewController.pageViewController(blueprintsViewController, viewControllerAfter: viewController) as? EmbeddedBlueprintViewController
    }

    func before(_ viewController: UIViewController) -> EmbeddedBlueprintViewController? {
      blueprintsViewController.pageViewController(blueprintsViewController, viewControllerBefore: viewController) as? EmbeddedBlueprintViewController
    }

    XCTAssertNil(before(blueprintViewController1))
    let blueprintViewController2 = try XCTUnwrap(after(blueprintViewController1))
    assertSnapshot(matching: blueprintViewController2, as: .image(on: .iPhone8Plus))

    blueprintsViewController.setViewControllers([blueprintViewController2], direction: .forward, animated: false, completion: nil)
    blueprintsViewController.pageViewController(blueprintsViewController, didFinishAnimating: true, previousViewControllers: [blueprintViewController1], transitionCompleted: true)
    assertSnapshot(matching: blueprintsNavigationController, as: .image(on: .iPhone8Plus))

    XCTAssertNil(after(blueprintViewController2))

    let newBlueprintViewController1 = try XCTUnwrap(before(blueprintViewController2))
    assertSnapshot(matching: newBlueprintViewController1, as: .image(on: .iPhone8Plus))
  }

  @available(iOS 12.0, *)
  func testFullscreen() throws {
    let building = try makeBuilding()
    let blueprintViewController = FullscreenBlueprintViewController()
    blueprintViewController.blueprint = building.blueprints[0]
    assertSnapshot(matching: blueprintViewController, as: .image(on: .iPhone8Plus))

    blueprintViewController.blueprint = nil
    assertSnapshot(matching: blueprintViewController, as: .image(on: .iPhone8Plus))

    blueprintViewController.blueprint = building.blueprints[1]
    assertSnapshot(matching: blueprintViewController, as: .image(on: .iPhone8Plus))

    if #available(iOS 13.0, *) {
      blueprintViewController.overrideUserInterfaceStyle = .dark
      assertSnapshot(matching: blueprintViewController, as: .image(on: .iPhone8Plus))
    }
  }

  @available(iOS 12.0, *)
  func testEmbedded() throws {
    let building = try makeBuilding()
    let blueprintViewController = EmbeddedBlueprintViewController()
    blueprintViewController.blueprint = building.blueprints[0]

    let size = CGSize(width: 300, height: 200)
    assertSnapshot(matching: blueprintViewController, as: .image(size: size))

    blueprintViewController.blueprint = nil
    assertSnapshot(matching: blueprintViewController, as: .image(size: size))

    blueprintViewController.blueprint = building.blueprints[1]
    assertSnapshot(matching: blueprintViewController, as: .image(size: size))

    if #available(iOS 13.0, *) {
      blueprintViewController.overrideUserInterfaceStyle = .dark
      assertSnapshot(matching: blueprintViewController, as: .image(size: size))
    }
  }

  func testEmpty() {
    let emptyViewController = BlueprintsEmptyViewController()
    assertSnapshot(matching: emptyViewController, as: .image(on: .iPhone8Plus))
  }

  private func makeBuilding() throws -> Building {
    let json = #"{"blueprints": [{"imageName": "k1-1", "title": "Building K - Level 1 (1)"}, {"imageName": "k1-2", "title": "Building K - Level 1 (2)"}], "coordinate": {"latitude": 50.81473311542874, "longitude": 4.381869697304779 }, "polygon": [{"latitude": 50.81445648728004, "longitude": 4.381859249480868 }, {"latitude": 50.81456833802892, "longitude": 4.3822159833125625 }, {"latitude": 50.8150089595851, "longitude": 4.381883389364191 }, {"latitude": 50.814900499280014, "longitude": 4.381518608904713 } ], "title": "K"}"#
    return try JSONDecoder().decode(Building.self, from: Data(json.utf8))
  }

  private func makeNoBlueprintsBuilding() throws -> Building {
    let json = #"{"blueprints": [], "coordinate": {"latitude": 50.81473311542874, "longitude": 4.381869697304779 }, "polygon": [{"latitude": 50.81445648728004, "longitude": 4.381859249480868 }, {"latitude": 50.81456833802892, "longitude": 4.3822159833125625 }, {"latitude": 50.8150089595851, "longitude": 4.381883389364191 }, {"latitude": 50.814900499280014, "longitude": 4.381518608904713 } ], "title": "Z"}"#
    return try JSONDecoder().decode(Building.self, from: Data(json.utf8))
  }
}
