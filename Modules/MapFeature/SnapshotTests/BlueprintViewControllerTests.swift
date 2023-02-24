@testable
import MapFeature
import SnapshotTesting
import XCTest

final class BlueprintViewControllerTests: XCTestCase {
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
  }

  func testEmpty() {
    let emptyViewController = BlueprintsEmptyViewController()
    assertSnapshot(matching: emptyViewController, as: .image(on: .iPhone8Plus))
  }

  private func makeBuilding() throws -> Building {
    let json = #"{"blueprints": [{"imageName": "k1-1", "title": "Building K - Level 1 (1)"}, {"imageName": "k1-2", "title": "Building K - Level 1 (2)"}, {"imageName": "k2", "title": "Building K - Level 2"}, {"imageName": "k3", "title": "Building K - Level 3"}, {"imageName": "k4", "title": "Building K - Level 4"} ], "coordinate": {"latitude": 50.81473311542874, "longitude": 4.381869697304779 }, "polygon": [{"latitude": 50.81445648728004, "longitude": 4.381859249480868 }, {"latitude": 50.81456833802892, "longitude": 4.3822159833125625 }, {"latitude": 50.8150089595851, "longitude": 4.381883389364191 }, {"latitude": 50.814900499280014, "longitude": 4.381518608904713 } ], "title": "K"}"#
    return try JSONDecoder().decode(Building.self, from: Data(json.utf8))
  }
}
