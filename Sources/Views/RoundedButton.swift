import UIKit

final class RoundedButton: UIButton {
    private lazy var size = CGSize(width: 1, height: 1)
    private lazy var rect = CGRect(origin: .zero, size: size)
    private lazy var renderer = UIGraphicsImageRenderer(size: size)

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        layer.cornerRadius = 4
        layer.masksToBounds = true

        setTitleColor(.fos_systemBackground, for: .normal)
        setBackgroundImage(makeNormalImage(), for: .normal)
        setBackgroundImage(makeHighlightedImage(), for: .highlighted)

        contentEdgeInsets = .init(top: 12, left: 12, bottom: 12, right: 12)
        titleLabel?.font = .fos_preferredFont(forTextStyle: .body, withSymbolicTraits: .traitBold)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 12.0, *), traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            setBackgroundImage(makeNormalImage(), for: .normal)
            setBackgroundImage(makeHighlightedImage(), for: .highlighted)
        }
    }

    private func makeNormalImage() -> UIImage? {
        renderer.image { context in
            context.cgContext.setFillColor(UIColor.fos_label.cgColor)
            context.cgContext.fill(rect)
        }
    }

    private func makeHighlightedImage() -> UIImage? {
        renderer.image { context in
            context.cgContext.setFillColor(UIColor.fos_label.withAlphaComponent(0.8).cgColor)
            context.cgContext.fill(rect)
        }
    }
}
