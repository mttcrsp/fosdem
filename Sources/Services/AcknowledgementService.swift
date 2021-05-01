import Foundation

final class AcknowledgementsService {
  enum Error: CustomNSError {
    case resourceNotFound
  }

  private let dataProvider: AcknowledgementsServiceDataProvider
  private let bundle: AcknowledgementsServiceBundle

  init(bundle: AcknowledgementsServiceBundle = Bundle.main, dataProvider: AcknowledgementsServiceDataProvider = AcknowledgementsServiceData()) {
    self.dataProvider = dataProvider
    self.bundle = bundle
  }

  func loadAcknowledgements() throws -> [Acknowledgement] {
    guard let url = bundle.url(forResource: "acknowledgements", withExtension: "json") else {
      throw Error.resourceNotFound
    }

    let data = try dataProvider.data(withContentsOf: url)
    let decoder = JSONDecoder()
    return try decoder.decode([Acknowledgement].self, from: data)
  }
}

/// @mockable
protocol AcknowledgementsServiceProtocol {
  func loadAcknowledgements() throws -> [Acknowledgement]
}

extension AcknowledgementsService: AcknowledgementsServiceProtocol {}

/// @mockable
protocol AcknowledgementsServiceBundle {
  func url(forResource name: String?, withExtension ext: String?) -> URL?
}

extension Bundle: AcknowledgementsServiceBundle {}

/// @mockable
protocol AcknowledgementsServiceDataProvider {
  func data(withContentsOf url: URL) throws -> Data
}

final class AcknowledgementsServiceData: AcknowledgementsServiceDataProvider {
  func data(withContentsOf url: URL) throws -> Data {
    try Data(contentsOf: url)
  }
}
