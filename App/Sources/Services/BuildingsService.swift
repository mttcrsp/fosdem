import Foundation

struct BuildingsService {
  enum Error: CustomNSError {
    case missingData, partialData
  }

  var loadBuildings: (@escaping ([Building], Error?) -> Void) -> Void
}

extension BuildingsService {
  init(bundleService: BuildingsServiceBundle, queue: DispatchQueue = .global()) {
    loadBuildings = { completion in
      queue.async {
        var buildings: [Building] = []

        let resources = ["aw", "f", "h", "j", "k", "u", "s"]
        for resource in resources {
          do {
            let buildingData = try bundleService.data(forResource: resource, withExtension: "json")
            let building = try JSONDecoder().decode(Building.self, from: buildingData)
            buildings.append(building)
          } catch {}
        }

        switch buildings.count {
        case resources.count:
          completion(buildings, nil)
        case 0:
          completion([], .missingData)
        case _:
          completion(buildings, .partialData)
        }
      }
    }
  }
}

/// @mockable
protocol BuildingsServiceProtocol {
  var loadBuildings: (@escaping ([Building], BuildingsService.Error?) -> Void) -> Void { get }
}

extension BuildingsService: BuildingsServiceProtocol {}

/// @mockable
protocol BuildingsServiceBundle {
  func data(forResource name: String?, withExtension ext: String?) throws -> Data
}

extension BundleService: BuildingsServiceBundle {}

protocol HasBuildingsService {
  var buildingsService: BuildingsServiceProtocol { get }
}
