import UIKit

final class MapControlView: UIControl {
  var title: String? {
    get { label.text }
    set { label.text = newValue }
  }

  var image: UIImage? {
    get { imageView.image }
    set { imageView.image = newValue }
  }

  override var accessibilityLabel: String? {
    get { super.accessibilityLabel ?? title }
    set { super.accessibilityLabel = newValue }
  }

  private let label = UILabel()
  private let imageView = UIImageView()

  private var compactConstraints: [NSLayoutConstraint] = []
  private var regularConstraints: [NSLayoutConstraint] = []

  override init(frame: CGRect) {
    super.init(frame: frame)

    isAccessibilityElement = true
    accessibilityTraits = .button

    imageView.contentMode = .center
    label.font = .fos_preferredFont(forTextStyle: .body)
    label.adjustsFontForContentSizeCategory = true
    label.textColor = tintColor

    let stackView = UIStackView(arrangedSubviews: [imageView, label])
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.isUserInteractionEnabled = false
    stackView.axis = .horizontal
    stackView.spacing = 10
    addSubview(stackView)

    regularConstraints = [
      stackView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
    ]

    compactConstraints = [
      stackView.topAnchor.constraint(equalTo: topAnchor),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
      stackView.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
      stackView.widthAnchor.constraint(equalTo: stackView.heightAnchor),
    ]
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var isHighlighted: Bool {
    didSet { alpha = isHighlighted ? 0.5 : 1 }
  }

  override func updateConstraints() {
    let isRegular = traitCollection.fos_hasRegularSizeClasses
    label.isHidden = !isRegular
    NSLayoutConstraint.activate(isRegular ? regularConstraints : compactConstraints)
    NSLayoutConstraint.deactivate(isRegular ? compactConstraints : regularConstraints)
    super.updateConstraints()
  }

  override func tintColorDidChange() {
    super.tintColorDidChange()
    label.textColor = tintColor
  }
}
