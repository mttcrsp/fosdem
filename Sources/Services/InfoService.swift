import UIKit

enum Info {
    case history, devrooms, transportation
    case bus, shuttle, train, car, plane, taxi
}

protocol InfoServiceBundle {
    func url(forResource name: String?, withExtension ext: String?) -> URL?
}

protocol InfoServiceDataProvider {
    func data(withContentsOf url: URL) throws -> Data
}

extension Bundle: InfoServiceBundle {}

final class InfoService {
    private let provider: InfoServiceDataProvider
    private let bundle: InfoServiceBundle
    private let queue: DispatchQueue

    init(queue: DispatchQueue = .global(), bundle: InfoServiceBundle = Bundle.main, provider: InfoServiceDataProvider = InfoServiceData()) {
        self.provider = provider
        self.bundle = bundle
        self.queue = queue
    }

    func loadAttributedText(for info: Info, completion: @escaping (NSAttributedString?) -> Void) {
        queue.async { [weak self] in
            do {
                guard let self = self else { return }

                guard let url = self.bundle.url(forResource: info.resource, withExtension: "html") else {
                    assertionFailure("Failed to locate html file for resource '\(info.resource)'")
                    return completion(nil)
                }

                let attributedData = try self.provider.data(withContentsOf: url)
                let attributedText = try NSMutableAttributedString(html: attributedData)

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

                let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
                let boldFont = UIFont(descriptor: descriptor.withSymbolicTraits(.traitBold) ?? descriptor, size: 0)
                let bodyFont = UIFont(descriptor: descriptor, size: 0)

                attributedText.addAttribute(.font, value: bodyFont, range: range)
                attributedText.addAttribute(.foregroundColor, value: UIColor.fos_label, range: range)

                for range in boldRanges {
                    attributedText.removeAttribute(.font, range: range)
                    attributedText.addAttribute(.font, value: boldFont, range: range)
                }

                for range in linkRanges {
                    attributedText.removeAttribute(.font, range: range)
                    attributedText.addAttribute(.font, value: bodyFont, range: range)
                }

                completion(attributedText)
            } catch {
                assertionFailure(error.localizedDescription)
                completion(nil)
            }
        }
    }
}

extension Info {
    var resource: String {
        switch self {
        case .history: return "history"
        case .devrooms: return "devrooms"
        case .transportation: return "transportation"
        case .bus: return "bus-tram"
        case .shuttle: return "shuttle"
        case .train: return "train"
        case .car: return "car"
        case .plane: return "plane"
        case .taxi: return "taxi"
        }
    }
}

private extension Dictionary where Key == NSAttributedString.Key, Value == Any {
    var containsBoldAttribute: Bool {
        guard let font = self[.font] as? UIFont else { return false }
        return font.fontDescriptor.symbolicTraits.contains(.traitBold)
    }

    var containsLinkAttribute: Bool {
        self[.link] != nil
    }
}

final class InfoServiceData: InfoServiceDataProvider {
    func data(withContentsOf url: URL) throws -> Data {
        try .init(contentsOf: url)
    }
}
