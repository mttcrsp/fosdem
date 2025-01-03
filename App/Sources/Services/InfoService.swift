import UIKit

enum Info: String {
  case history, devrooms, transportation
  case bus, train, car, plane, taxi
  case legal
}

final class InfoService {
  private let queue: DispatchQueue
  private let bundleService: InfoServiceBundle

  init(queue: DispatchQueue = .global(), bundleService: InfoServiceBundle) {
    self.bundleService = bundleService
    self.queue = queue
  }

  func loadAttributedText(for info: Info, completion: @escaping (Result<NSAttributedString, Error>) -> Void) {
    queue.async { [weak self] in
      do {
        guard let self else { return }

        let attributedData = try bundleService.data(forResource: info.resource, withExtension: "html")
        let attributedText = try NSMutableAttributedString.fromHTML(attributedData) as NSMutableAttributedString

        let string = attributedText.string
        let lowerbound = string.startIndex
        let upperbound = string.endIndex
        let range = NSRange(lowerbound ..< upperbound, in: string)

        var boldRanges: [NSRange] = []
        var linkRanges: [NSRange] = []

        attributedText.enumerateAttributes(in: range) { attributes, range, _ in
          if attributes.containsLinkAttribute {
            linkRanges.append(range)
          } else if attributes.containsBoldAttribute {
            boldRanges.append(range)
          }
        }

        let boldFont = UIFont.fos_preferredFont(forTextStyle: .body, withSymbolicTraits: .traitBold)
        let bodyFont = UIFont.fos_preferredFont(forTextStyle: .body)

        attributedText.addAttribute(.font, value: bodyFont, range: range)
        attributedText.addAttribute(.foregroundColor, value: UIColor.label, range: range)

        for range in boldRanges {
          attributedText.removeAttribute(.font, range: range)
          attributedText.addAttribute(.font, value: boldFont, range: range)
        }

        for range in linkRanges {
          attributedText.removeAttribute(.font, range: range)
          attributedText.addAttribute(.font, value: bodyFont, range: range)
        }

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
