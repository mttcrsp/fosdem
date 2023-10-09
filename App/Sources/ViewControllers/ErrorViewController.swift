import UIKit

final class ErrorViewController: UIViewController {
  var onAppStoreTap: (() -> Void)? {
    didSet { appStoreButton.isHidden = onAppStoreTap == nil }
  }

  private let titleLabel = UILabel()
  private let messageLabel = UILabel()
  private let appStoreButton = RoundedButton()

  init() {
    super.init(nibName: nil, bundle: nil)

    for label in [titleLabel, messageLabel] {
      label.numberOfLines = 0
      label.textAlignment = .center
    }

    titleLabel.textColor = .label
    titleLabel.text = L10n.Error.Functionality.title
    titleLabel.font = .fos_preferredFont(forTextStyle: .title2, withSymbolicTraits: [.traitBold, .traitItalic])

    messageLabel.textColor = .secondaryLabel
    messageLabel.font = .fos_preferredFont(forTextStyle: .headline)
    messageLabel.text = L10n.Error.Functionality.message

    appStoreButton.isHidden = true
    appStoreButton.accessibilityIdentifier = "appstore"
    appStoreButton.translatesAutoresizingMaskIntoConstraints = false
    appStoreButton.addTarget(self, action: #selector(didTapAppStore), for: .touchUpInside)
    appStoreButton.setTitle(L10n.Error.Functionality.action, for: .normal)

    let stackView = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.alignment = .center
    stackView.axis = .vertical
    stackView.spacing = 16

    view.addSubview(stackView)
    view.addSubview(appStoreButton)
    view.backgroundColor = .systemBackground

    NSLayoutConstraint.activate([
      stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      appStoreButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      appStoreButton.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -16),
      appStoreButton.bottomAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.bottomAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func didTapAppStore() {
    onAppStoreTap?()
  }
}
