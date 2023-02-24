import Foundation

enum BuildingsServiceError: CustomNSError {
  case missingData, partialData
}

/// @mockable
protocol BuildingsService {
  func loadBuildings(completion: @escaping ([Building], BuildingsServiceError?) -> Void)
}

final class BuildingsServiceImpl {
  private let bundleService: BundleService
  private let queue: DispatchQueue

  init(bundleService: BundleService, queue: DispatchQueue = .global()) {
    self.bundleService = bundleService
    self.queue = queue
  }

  func loadBuildings(completion: @escaping ([Building], BuildingsServiceError?) -> Void) {
    queue.async { [weak self] in
      guard let self = self else { return }

      var buildings: [Building] = []

      let resources = ["aw", "f", "h", "j", "k", "u", "s"]
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
        completion([], BuildingsServiceError.missingData)
      case _:
        completion(buildings, BuildingsServiceError.partialData)
      }
    }
  }
}

extension BuildingsServiceImpl: BuildingsService {}
