import Foundation

final class BuildingsService {
  enum Error: CustomNSError {
    case missingData, partialData
  }

  private let bundleService: BuildingsServiceBundle
  private let queue: DispatchQueue

  init(bundleService: BuildingsServiceBundle, queue: DispatchQueue = .global()) {
    self.bundleService = bundleService
    self.queue = queue
  }

  func loadBuildings(completion: @escaping ([Building], Error?) -> Void) {
    queue.async { [weak self] in
      guard let self = self else { return }

      var buildings: [Building] = []

      let resources = ["aw", "f", "h", "j", "k", "u"]
      for resource in resources {
        do {
          let buildingData = try self.bundleService.data(forResource: resource, withExtension: "json")
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

/// @mockable
protocol BuildingsServiceProtocol {
  func loadBuildings(completion: @escaping ([Building], BuildingsService.Error?) -> Void)
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
