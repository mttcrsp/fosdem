@testable
import Fosdem
import XCTest

final class BuildingTests: XCTestCase {
  func testDecode() throws {
    let resources = ["j", "aw", "f1", "h", "j", "k", "u"]

    for resource in resources {
      let data = try BundleDataLoader().data(forResource: resource, withExtension: "json")
      let building = try JSONDecoder().decode(Building.self, from: data)
      XCTAssertNotNil(building.title, "Invalid title for building '\(resource)'")
      XCTAssertFalse(building.glyph.isEmpty, "Invalid glyph for building '\(resource)'")
      XCTAssertGreaterThanOrEqual(building.polygon.pointCount, 4, "Invalid polygon for building '\(resource)'")
    }
  }
}
