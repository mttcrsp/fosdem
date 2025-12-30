import UIKit

/// @mockable
protocol WelcomeViewControllerDelegate: AnyObject {
  func welcomeViewControllerDidTapContinue(_ welcomeViewController: WelcomeViewController)
}

final class WelcomeViewController: UIViewController {
  weak var delegate: WelcomeViewControllerDelegate?

  var showsContinue = false {
    didSet { showsContinueChanged() }
  }

  private var observers: [NSObjectProtocol] = []

  private lazy var stackView: UIStackView = {
    let stackView = UIStackView(arrangedSubviews: [imageView, messageLabel])
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.alignment = .center
    stackView.axis = .vertical
    stackView.spacing = 32
    return stackView
  }()

  private let imageView = UIImageView(image: Asset.Search.logo.image)

  private lazy var messageLabel: UILabel = {
    let messageLabel = UILabel()
    messageLabel.adjustsFontForContentSizeCategory = true
    messageLabel.attributedText = makeAttributedText()
    messageLabel.textAlignment = .center
    messageLabel.numberOfLines = 0
    return messageLabel
  }()

  private lazy var continueButton: UIButton = {
    let continueButton = UIButton.fos_rounded()
    continueButton.accessibilityIdentifier = "continue"
    continueButton.setTitle(L10n.Welcome.continue, for: .normal)
    continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
    return continueButton
  }()

  private let year: Int

  init(year: Int) {
    self.year = year
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.contentInset.bottom = 20
    scrollView.contentInset.top = 20
    scrollView.addSubview(stackView)

    view.addSubview(scrollView)
    view.accessibilityIdentifier = "welcome"
    view.backgroundColor = .systemGroupedBackground

    NSLayoutConstraint.activate([
      messageLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 500),
      continueButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),

      messageLabel.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
      messageLabel.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),

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
      messageLabel.attributedText = makeAttributedText()
    }
  }

  @objc private func continueTapped() {
    delegate?.welcomeViewControllerDidTapContinue(self)
  }

  private func showsContinueChanged() {
    if showsContinue {
      stackView.addArrangedSubview(continueButton)
    } else {
      stackView.removeArrangedSubview(continueButton)
      continueButton.removeFromSuperview()
    }
  }

  private func makeAttributedText() -> NSAttributedString {
    let titleFont: UIFont = .fos_preferredFont(forTextStyle: .title1, withSymbolicTraits: .traitBold)
    let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: UIColor.label]
    let titleString = L10n.Welcome.title(year)
    let messageFont: UIFont = .fos_preferredFont(forTextStyle: .title3, withSymbolicTraits: .traitItalic)
    let messageAttributes: [NSAttributedString.Key: Any] = [.font: messageFont, .foregroundColor: UIColor.label]
    let messageString = L10n.Welcome.message

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
