import Foundation

enum MoreItem: CaseIterable {
    #if DEBUG
        case time
    #endif

    case code
    case years
    case history
    case devrooms
    case transportation
    case acknowledgements
}

extension MoreItem {
    var title: String {
        switch self {
        case .code: return NSLocalizedString("code.title", comment: "")
        case .years: return NSLocalizedString("years.title", comment: "")
        case .history: return NSLocalizedString("history.title", comment: "")
        case .devrooms: return NSLocalizedString("devrooms.title", comment: "")
        case .transportation: return NSLocalizedString("transportation.title", comment: "")
        case .acknowledgements: return NSLocalizedString("acknowledgements.title", comment: "")
        #if DEBUG
            case .time: return NSLocalizedString("time.title", comment: "")
        #endif
        }
    }

    var info: Info? {
        switch self {
        case .history: return .history
        case .devrooms: return .devrooms
        case .transportation: return .transportation
        case .code, .years, .acknowledgements: return nil
        #if DEBUG
            case .time: return nil
        #endif
        }
    }
}
