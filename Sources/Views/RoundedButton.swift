import UIKit

final class RoundedButton: UIButton {
  private lazy var size = CGSize(width: 1, height: 1)
  private lazy var rect = CGRect(origin: .zero, size: size)
  private lazy var renderer = UIGraphicsImageRenderer(size: size)

  override init(frame: CGRect) {
    super.init(frame: frame)

    if #available(iOS 15.0, *) {
      configuration = UIButton.Configuration.filled()
      configuration?.cornerStyle = .small
      configuration?.buttonSize = .large
      configuration?.titleTextAttributesTransformer = .init { configuration in
        var configuration = configuration
        configuration.font = .fos_preferredFont(forTextStyle: .body, withSymbolicTraits: .traitBold)
        return configuration
      }
    } else {
      layer.cornerRadius = 4
      layer.masksToBounds = true

      imageView?.tintColor = .fos_systemBackground
      setTitleColor(.fos_systemBackground, for: .normal)
      setBackgroundImage(makeNormalImage(), for: .normal)
      setBackgroundImage(makeHighlightedImage(), for: .highlighted)

      contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
      titleLabel?.font = .fos_preferredFont(forTextStyle: .body, withSymbolicTraits: .traitBold)
    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension RoundedButton {
  override func tintColorDidChange() {
    super.tintColorDidChange()

    if #available(iOS 15.0, *) {} else {
      setBackgroundImage(makeNormalImage(), for: .normal)
      setBackgroundImage(makeHighlightedImage(), for: .highlighted)
    }
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    if #available(iOS 15.0, *) {} else {
      if #available(iOS 12.0, *), traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
        setBackgroundImage(makeNormalImage(), for: .normal)
        setBackgroundImage(makeHighlightedImage(), for: .highlighted)
      }
    }
  }

  private func makeNormalImage() -> UIImage? {
    renderer.image { context in
      context.cgContext.setFillColor(tintColor.cgColor)
      context.cgContext.fill(rect)
    }
  }

  private func makeHighlightedImage() -> UIImage? {
    renderer.image { context in
      context.cgContext.setFillColor(tintColor.withAlphaComponent(0.8).cgColor)
      context.cgContext.fill(rect)
    }
  }
}
