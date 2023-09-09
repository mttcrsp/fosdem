import Foundation

struct BuildingsClient {
  enum Error: CustomNSError {
    case missingData, partialData
  }

  var loadBuildings: (@escaping ([Building], Error?) -> Void) -> Void
}

extension BuildingsClient {
  init(bundleClient: BuildingsClientBundle, queue: DispatchQueue = .global()) {
    loadBuildings = { completion in
      queue.async {
        var buildings: [Building] = []

        let resources = ["aw", "f", "h", "j", "k", "u", "s"]
        for resource in resources {
          do {
            let buildingData = try bundleClient.data(resource, "json")
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
protocol BuildingsClientProtocol {
  var loadBuildings: (@escaping ([Building], BuildingsClient.Error?) -> Void) -> Void { get }
}

extension BuildingsClient: BuildingsClientProtocol {}

/// @mockable
protocol BuildingsClientBundle {
  var data: (String?, String?) throws -> Data { get }
}

extension BundleClient: BuildingsClientBundle {}

protocol HasBuildingsClient {
  var buildingsClient: BuildingsClientProtocol { get }
}
