import UIKit

final class WelcomeViewController: UIViewController {
  private var observers: [NSObjectProtocol] = []
  private lazy var label = UILabel()

  private let year: Int

  init(year: Int) {
    self.year = year
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let imageView = UIImageView()
    imageView.image = UIImage(named: "logo")

    label.adjustsFontForContentSizeCategory = true
    label.attributedText = makeAttributedText()
    label.textAlignment = .center
    label.numberOfLines = 0

    let stackView = UIStackView(arrangedSubviews: [imageView, label])
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.alignment = .center
    stackView.axis = .vertical
    stackView.spacing = 32

    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(stackView)

    view.addSubview(scrollView)
    view.accessibilityIdentifier = "welcome"
    view.backgroundColor = .groupTableViewBackground

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.topAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

      stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
      stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
      stackView.leadingAnchor.constraint(equalTo: scrollView.readableContentGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: scrollView.readableContentGuide.trailingAnchor),
    ])

    observers = [
      scrollView.observe(\.contentSize) { scrollView, _ in
        scrollView.adjustTopContentInsetForVerticalCentering()
      },
      scrollView.observe(\.bounds) { scrollView, _ in
        scrollView.adjustTopContentInsetForVerticalCentering()
      },
    ]
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
      label.attributedText = makeAttributedText()
    }
  }

  private func makeAttributedText() -> NSAttributedString {
    let titleFont: UIFont = .fos_preferredFont(forTextStyle: .title1, withSymbolicTraits: .traitBold)
    let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: UIColor.fos_label]
    let titleString = FOSLocalizedString(format: "welcome.title", year)
    let messageFont: UIFont = .fos_preferredFont(forTextStyle: .title3, withSymbolicTraits: .traitItalic)
    let messageAttributes: [NSAttributedString.Key: Any] = [.font: messageFont, .foregroundColor: UIColor.fos_label]
    let messageString = FOSLocalizedString("welcome.message")

    let attributedTitle = NSAttributedString(string: titleString, attributes: titleAttributes)
    let attributedMessage = NSAttributedString(string: messageString, attributes: messageAttributes)
    let attributedSpacer = NSAttributedString(string: "\n\n")

    let attributedText = NSMutableAttributedString()
    attributedText.append(attributedTitle)
    attributedText.append(attributedSpacer)
    attributedText.append(attributedMessage)
    return attributedText
  }
}

private extension UIScrollView {
  func adjustTopContentInsetForVerticalCentering() {
    contentInset.top = max(0, (bounds.height - contentSize.height) / 2)
  }
}
