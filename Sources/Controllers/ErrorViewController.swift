import UIKit

final class ErrorViewController: UIViewController {
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

        titleLabel.textColor = .fos_label
        titleLabel.text = NSLocalizedString("error.functionality.title", comment: "")
        titleLabel.font = .fos_preferredFont(forTextStyle: .title2, withSymbolicTraits: [.traitBold, .traitItalic])

        messageLabel.textColor = .fos_secondaryLabel
        messageLabel.font = .fos_preferredFont(forTextStyle: .headline)
        messageLabel.text = NSLocalizedString("error.functionality.message", comment: "")

        actionButton.isHidden = true
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addTarget(self, action: #selector(didTapAction), for: .touchUpInside)
        actionButton.setTitle(NSLocalizedString("error.functionality.action", comment: ""), for: .normal)

        let stackView = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.spacing = 16

        view.addSubview(stackView)
        view.addSubview(actionButton)
        view.backgroundColor = .fos_systemBackground

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

            actionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            actionButton.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -16),
            actionButton.bottomAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.bottomAnchor),
        ])
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didTapAction() {
        if let url = URL.fosdemAppStore {
            UIApplication.shared.open(url)
        }
    }
}
