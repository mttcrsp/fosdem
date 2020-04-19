import Foundation

enum MoreSection: CaseIterable {
    case about
    case other
    #if DEBUG
        case debug
    #endif
}

extension MoreSection {
    var items: [MoreItem] {
        switch self {
        #if DEBUG
            case .debug: return [.time]
        #endif
        case .other: return [.years, .code]
        case .about: return [.history, .devrooms, .transportation]
        }
    }

    var title: String? {
        switch self {
        #if DEBUG
            case .debug: return "Debug"
        #endif
        case .about: return NSLocalizedString("more.section.about", comment: "")
        case .other: return NSLocalizedString("more.section.other", comment: "")
        }
    }
}
