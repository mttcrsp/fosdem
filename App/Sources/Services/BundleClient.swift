import Foundation

struct BundleClient {
  enum Error: CustomNSError {
    case resourceNotFound
  }

  var data: (String?, String?) throws -> Data
}

extension BundleClient {
  init(bundle: BundleClientBundle = Bundle.main, dataProvider: BundleClientDataProvider = BundleClientData()) {
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
protocol BundleClientBundle {
  func url(forResource name: String?, withExtension ext: String?) -> URL?
}

extension Bundle: BundleClientBundle {}

/// @mockable
protocol BundleClientDataProvider {
  func data(withContentsOf url: URL) throws -> Data
}

final class BundleClientData: BundleClientDataProvider {
  func data(withContentsOf url: URL) throws -> Data {
    try Data(contentsOf: url)
  }
}
