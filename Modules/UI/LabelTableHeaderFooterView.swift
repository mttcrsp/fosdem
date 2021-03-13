import UIKit

public final class LabelTableHeaderFooterView: UITableViewHeaderFooterView {
  public var text: String? {
    get { label.text }
    set { label.text = newValue }
  }

  public var textColor: UIColor? {
    get { label.textColor }
    set { label.textColor = newValue }
  }

  public var font: UIFont? {
    get { label.font }
    set { label.font = newValue }
  }

  private let label = UILabel()

  override public init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    label.numberOfLines = 0
    label.textColor = .fos_secondaryLabel
    label.adjustsFontForContentSizeCategory = true
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .fos_preferredFont(forTextStyle: .callout)

    contentView.addSubview(label)

    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
      label.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
      label.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
      label.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
    ])
  }

  @available(*, unavailable)
  public required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
