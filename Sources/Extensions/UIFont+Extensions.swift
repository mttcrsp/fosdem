import UIKit

extension UIFont {
    enum Style {
        case title, headline, body, action
    }

    static func preferredFont(for style: Style) -> UIFont {
        let font = style.makeFont()

        if #available(iOS 11.0, *) {
            return UIFontMetrics.default.scaledFont(for: font)
        } else {
            return font
        }
    }

    static func preferredUnscaledFont(for style: Style) -> UIFont {
        style.makeFont()
    }
}

private extension UIFont.Style {
    func makeFont() -> UIFont {
        .systemFont(ofSize: size, weight: weight)
    }

    var size: CGFloat {
        switch self {
        case .body: return 15
        case .title: return 28
        case .action: return 15
        case .headline: return 21
        }
    }

    var weight: UIFont.Weight {
        switch self {
        case .body: return .regular
        case .title: return .bold
        case .action: return .semibold
        case .headline: return .semibold
        }
    }
}
