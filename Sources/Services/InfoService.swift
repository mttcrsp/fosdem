import Foundation

enum Info {
    case history, devrooms, transportation
    case bus, shuttle, train, car, plane, taxi
}

protocol InfoServiceBundle {
    func url(forResource name: String?, withExtension ext: String?) -> URL?
}

extension Bundle: InfoServiceBundle {}

final class InfoService {
    let bundle: InfoServiceBundle

    init(bundle: InfoServiceBundle = Bundle.main) {
        self.bundle = bundle
    }

    func loadAttributedText(for info: Info, completion: @escaping (NSAttributedString?) -> Void) {
        guard let url = bundle.url(forResource: info.resource, withExtension: "html") else {
            assertionFailure("Failed to locate html file for resource '\(info.resource)'")
            return completion(nil)
        }

        DispatchQueue.main.async {
            do {
                completion(try NSAttributedString(html: try Data(contentsOf: url)))
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
