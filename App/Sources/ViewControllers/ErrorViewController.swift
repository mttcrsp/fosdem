import UIKit

/// @mockable
protocol ErrorViewControllerDelegate: AnyObject {
  func errorViewControllerDidTapAppStore(_ errorViewController: ErrorViewController)
}

final class ErrorViewController: UIViewController {
  weak var delegate: ErrorViewControllerDelegate?

  var showsAppStoreButton: Bool {
    get { !actionButton.isHidden }
    set { actionButton.isHidden = !newValue }
  }

  private let titleLabel = UILabel()
  private let messageLabel = UILabel()
  private let actionButton = RoundedButton()

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

    actionButton.isHidden = true
    actionButton.accessibilityIdentifier = "appstore"
    actionButton.translatesAutoresizingMaskIntoConstraints = false
    actionButton.addTarget(self, action: #selector(didTapAction), for: .touchUpInside)
    actionButton.setTitle(L10n.Error.Functionality.action, for: .normal)

    let stackView = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.alignment = .center
    stackView.axis = .vertical
    stackView.spacing = 16

    view.addSubview(stackView)
    view.addSubview(actionButton)
    view.backgroundColor = .systemBackground

    NSLayoutConstraint.activate([
      stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      actionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      actionButton.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -16),
      actionButton.bottomAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.bottomAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func didTapAction() {
    delegate?.errorViewControllerDidTapAppStore(self)
  }
}
