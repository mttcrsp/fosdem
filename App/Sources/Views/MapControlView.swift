import UIKit

final class MapControlView: UIControl {
  var title: String? {
    get { label.text }
    set { label.text = newValue }
  }

  var image: UIImage? {
    get { imageView.image }
    set { imageView.image = newValue?.withConfiguration(UIImage.SymbolConfiguration(font: font)) }
  }

  override var accessibilityLabel: String? {
    get { super.accessibilityLabel ?? title }
    set { super.accessibilityLabel = newValue }
  }

  private let label = UILabel()
  private let imageView = UIImageView()
  private let font = UIFont.fos_preferredFont(forTextStyle: .body)
  private var compactConstraints: [NSLayoutConstraint] = []
  private var regularConstraints: [NSLayoutConstraint] = []

  override init(frame: CGRect) {
    super.init(frame: frame)

    isAccessibilityElement = true
    accessibilityTraits = .button

    label.font = font
    label.adjustsFontForContentSizeCategory = true
    label.textColor = tintColor

    for subview in [imageView, label] {
      subview.translatesAutoresizingMaskIntoConstraints = false
      addSubview(subview)
    }

    regularConstraints = [
      imageView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
      imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
      imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10),
      label.firstBaselineAnchor.constraint(equalTo: imageView.firstBaselineAnchor),
      label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
    ]

    compactConstraints = [
      imageView.topAnchor.constraint(equalTo: topAnchor),
      imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
      imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
      imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
      imageView.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
      imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor),
    ]
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var isHighlighted: Bool {
    didSet { alpha = isHighlighted ? 0.5 : 1 }
  }

  override func updateConstraints() {
    let isRegular = traitCollection.fos_hasRegularSizeClasses
    label.isHidden = !isRegular
    imageView.contentMode = isRegular ? .scaleAspectFit : .center
    NSLayoutConstraint.activate(isRegular ? regularConstraints : compactConstraints)
    NSLayoutConstraint.deactivate(isRegular ? compactConstraints : regularConstraints)
    super.updateConstraints()
  }

  override func tintColorDidChange() {
    super.tintColorDidChange()
    label.textColor = tintColor
  }
}
