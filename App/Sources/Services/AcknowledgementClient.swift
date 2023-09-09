import Foundation

struct AcknowledgementsClient {
  enum Error: CustomNSError {
    case resourceNotFound
  }

  var loadAcknowledgements: () throws -> [Acknowledgement]
}

extension AcknowledgementsClient {
  init(bundle: AcknowledgementsClientBundle = Bundle.main, dataProvider: AcknowledgementsClientDataProvider = AcknowledgementsClientData()) {
    loadAcknowledgements = {
      guard let url = bundle.url(forResource: "acknowledgements", withExtension: "json") else {
        throw Error.resourceNotFound
      }

      let data = try dataProvider.data(withContentsOf: url)
      let decoder = JSONDecoder()
      return try decoder.decode([Acknowledgement].self, from: data)
    }
  }
}

/// @mockable
protocol AcknowledgementsClientProtocol {
  var loadAcknowledgements: () throws -> [Acknowledgement] { get }
}

extension AcknowledgementsClient: AcknowledgementsClientProtocol {}

/// @mockable
protocol AcknowledgementsClientBundle {
  func url(forResource name: String?, withExtension ext: String?) -> URL?
}

extension Bundle: AcknowledgementsClientBundle {}

/// @mockable
protocol AcknowledgementsClientDataProvider {
  func data(withContentsOf url: URL) throws -> Data
}

final class AcknowledgementsClientData: AcknowledgementsClientDataProvider {
  func data(withContentsOf url: URL) throws -> Data {
    try Data(contentsOf: url)
  }
}

protocol HasAcknowledgementsClient {
  var acknowledgementsClient: AcknowledgementsClientProtocol { get }
}
