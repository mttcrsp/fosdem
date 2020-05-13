import UIKit

final class TableBackgroundView: UIView {
    var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    var message: String? {
        get { messageLabel.text }
        set { messageLabel.text = newValue }
    }

    private let titleLabel = UILabel()
    private let messageLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        for label in [titleLabel, messageLabel] {
            label.numberOfLines = 0
            label.textColor = .fos_label
            label.textAlignment = .center
        }

        titleLabel.font = .fos_preferredFont(forTextStyle: .title2, withSymbolicTraits: .traitBold)
        messageLabel.font = .fos_preferredFont(forTextStyle: .body, withSymbolicTraits: .traitItalic)

        let stackView = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: readableContentGuide.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
        ])
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
