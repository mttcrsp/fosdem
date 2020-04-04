@testable
import Fosdem
import XCTest

final class BuildingTests: XCTestCase {
    func testDecode() {
        let resources = ["j", "aw", "f1", "h", "j", "k", "u"]

        for resource in resources {
            guard let data = BundleDataLoader().data(forResource: resource, withExtension: "json") else {
                return XCTFail("Unable to load data for building '\(resource)'")
            }

            do {
                let building = try JSONDecoder().decode(Building.self, from: data)
                XCTAssertNotNil(building.title, "Invalid title for building '\(resource)'")
                XCTAssertFalse(building.glyph.isEmpty, "Invalid glyph for building '\(resource)'")
                XCTAssertGreaterThanOrEqual(building.polygon.pointCount, 4, "Invalid polygon for building '\(resource)'")
            } catch {
                XCTFail("Failed to decode data for building '\(resource)': \(error)")
            }
        }
    }
}
