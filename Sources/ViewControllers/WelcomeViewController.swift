import UIKit

final class WelcomeViewController: UIViewController {
    private lazy var scrollView = UIScrollView()
    private lazy var imageView = UIImageView()
    private lazy var label = UILabel()

    override func loadView() {
        view = scrollView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.image = UIImage(named: "logo")

        let titleFont: UIFont = .fos_preferredFont(forTextStyle: .title1, withSymbolicTraits: .traitBold)
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: UIColor.fos_label]
        let titleString = NSLocalizedString("welcome.title", comment: "")

        let messageFont: UIFont = .fos_preferredFont(forTextStyle: .title3)
        let messageAttributes: [NSAttributedString.Key: Any] = [.font: messageFont, .foregroundColor: UIColor.fos_label]
        let messageString = NSLocalizedString("welcome.message", comment: "")

        let attributedTitle = NSAttributedString(string: titleString, attributes: titleAttributes)
        let attributedMessage = NSAttributedString(string: messageString, attributes: messageAttributes)
        let attributedSpacer = NSAttributedString(string: "\n\n")

        let attributedText = NSMutableAttributedString()
        attributedText.append(attributedTitle)
        attributedText.append(attributedSpacer)
        attributedText.append(attributedMessage)
        label.attributedText = attributedText
        label.textAlignment = .center
        label.numberOfLines = 0

        let stackView = UIStackView(arrangedSubviews: [imageView, label])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.spacing = 32

        view.addSubview(stackView)
        view.backgroundColor = .groupTableViewBackground

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: view.readableContentGuide.topAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.readableContentGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.readableContentGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.readableContentGuide.trailingAnchor),
        ])
    }
}
