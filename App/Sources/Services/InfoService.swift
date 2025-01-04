import UIKit

enum Info: String {
  case history, devrooms, transportation
  case bus, train, car, plane, taxi
  case legal
}

final class InfoService {
  enum Error: CustomNSError {
    case htmlParsingFailed
    case htmlRenderingFailed
  }
  
  private let queue: DispatchQueue
  private let bundleService: InfoServiceBundle

  init(queue: DispatchQueue = .global(), bundleService: InfoServiceBundle) {
    self.bundleService = bundleService
    self.queue = queue
  }

  func loadAttributedText(for info: Info, completion: @escaping (Result<NSAttributedString, Swift.Error>) -> Void) {
    queue.async { [weak self] in
      guard let self else { return }

      do {
        let data = try bundleService.data(forResource: info.resource, withExtension: "html")
        
        guard let html = HTMLParser().parse(String(decoding: data, as: UTF8.self))
        else { throw Error.htmlParsingFailed }
        
        guard let attributedText = HTMLRenderer().render(html)
        else { throw Error.htmlRenderingFailed }
        
        completion(.success(attributedText))
      } catch {
        completion(.failure(error))
      }
    }
  }
}

extension Info {
  var accessibilityIdentifier: String {
    rawValue
  }
}

private extension Info {
  var resource: String {
    switch self {
    case .history:
      "history"
    case .devrooms:
      "devrooms"
    case .transportation:
      "transportation"
    case .bus:
      "bus-tram"
    case .train:
      "train"
    case .car:
      "car"
    case .plane:
      "plane"
    case .taxi:
      "taxi"
    case .legal:
      "legal"
    }
  }
}

private extension [NSAttributedString.Key: Any] {
  var containsBoldAttribute: Bool {
    guard let font = self[.font] as? UIFont else { return false }
    return font.fontDescriptor.symbolicTraits.contains(.traitBold)
  }

  var containsLinkAttribute: Bool {
    self[.link] != nil
  }
}

/// @mockable
protocol InfoServiceProtocol {
  func loadAttributedText(for info: Info, completion: @escaping (Result<NSAttributedString, Error>) -> Void)
}

extension InfoService: InfoServiceProtocol {}

/// @mockable
protocol InfoServiceBundle {
  func data(forResource name: String?, withExtension ext: String?) throws -> Data
}

protocol HasInfoService {
  var infoService: InfoServiceProtocol { get }
}
