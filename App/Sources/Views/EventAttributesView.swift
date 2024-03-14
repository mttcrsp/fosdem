import UIKit

final class EventAttributesView: UIView {
  private let stackView = UIStackView()

  override init(frame: CGRect) {
    super.init(frame: frame)

    stackView.axis = .vertical
    stackView.spacing = 16
    stackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stackView)

    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
    ])
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    layer.borderWidth = 1 / traitCollection.displayScale
    layer.borderColor = UIColor.separator.cgColor
    layer.cornerRadius = 4
    layer.masksToBounds = true
  }

  func addArrangedSubview(_ attributeView: EventAttributeView) {
    stackView.addArrangedSubview(attributeView)
  }
}

final class EventAttributeView: UIControl {
  var text: String? {
    get { label.text }
    set { label.text = newValue }
  }

  var image: UIImage? {
    get { imageView.image }
    set { imageView.image = newValue }
  }

  override var isHighlighted: Bool {
    didSet { alpha = isHighlighted ? 0.5 : 1 }
  }

  private let imageView = UIImageView()
  private let label = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)

    isAccessibilityElement = true
    accessibilityTraits = .staticText

    for subview in [imageView, label] {
      subview.translatesAutoresizingMaskIntoConstraints = false
      addSubview(subview)
    }

    label.numberOfLines = 0
    label.adjustsFontForContentSizeCategory = true
    label.font = .fos_preferredFont(forTextStyle: .body)

    imageView.setContentCompressionResistancePriority(.required, for: .horizontal)

    NSLayoutConstraint.activate([
      imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
      imageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
      imageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
      imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
      imageView.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -10),

      label.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
      label.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
      label.centerYAnchor.constraint(equalTo: centerYAnchor),
      label.trailingAnchor.constraint(equalTo: trailingAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
    super.addTarget(target, action: action, for: controlEvents)
    didChangeTargets()
  }

  override func removeTarget(_ target: Any?, action: Selector?, for controlEvents: UIControl.Event) {
    super.removeTarget(target, action: action, for: controlEvents)
    didChangeTargets()
  }

  private func didChangeTargets() {
    isUserInteractionEnabled = !allTargets.isEmpty
    accessibilityTraits = isUserInteractionEnabled ? .staticText : .button
  }
}
