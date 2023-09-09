import Foundation

struct BundleService {
  enum Error: CustomNSError {
    case resourceNotFound
  }

  var data: (String?, String?) throws -> Data
}

extension BundleService {
  init(bundle: BundleServiceBundle = Bundle.main, dataProvider: BundleServiceDataProvider = BundleServiceData()) {
    data = { name, ext in
      if let url = bundle.url(forResource: name, withExtension: ext) {
        try dataProvider.data(withContentsOf: url)
      } else {
        throw Error.resourceNotFound
      }
    }
  }
}

/// @mockable
protocol BundleServiceBundle {
  func url(forResource name: String?, withExtension ext: String?) -> URL?
}

extension Bundle: BundleServiceBundle {}

/// @mockable
protocol BundleServiceDataProvider {
  func data(withContentsOf url: URL) throws -> Data
}

final class BundleServiceData: BundleServiceDataProvider {
  func data(withContentsOf url: URL) throws -> Data {
    try Data(contentsOf: url)
  }
}
