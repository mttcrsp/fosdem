import UIKit

final class LabelTableHeaderFooterView: UITableViewHeaderFooterView {
  var text: String? {
    get { label.text }
    set { label.text = newValue }
  }

  var textColor: UIColor? {
    get { label.textColor }
    set { label.textColor = newValue }
  }

  var font: UIFont? {
    get { label.font }
    set { label.font = newValue }
  }

  private let label = UILabel()

  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    label.numberOfLines = 0
    label.textColor = .secondaryLabel
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
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
