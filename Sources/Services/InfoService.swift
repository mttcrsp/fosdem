import UIKit

enum Info {
    case history, devrooms, transportation
    case bus, shuttle, train, car, plane, taxi
}

protocol InfoServiceBundle {
    func data(forResource name: String?, withExtension ext: String?) throws -> Data
}

final class InfoService {
    private let queue: DispatchQueue
    private let bundleService: InfoServiceBundle

    init(queue: DispatchQueue = .global(), bundleService: InfoServiceBundle) {
        self.bundleService = bundleService
        self.queue = queue
    }

    func loadAttributedText(for info: Info, completion: @escaping (NSAttributedString?) -> Void) {
        queue.async { [weak self] in
            do {
                guard let self = self else { return }

                let attributedData = try self.bundleService.data(forResource: info.resource, withExtension: "html")
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

extension BundleService: InfoServiceBundle {}
