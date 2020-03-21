import UIKit

final class TableBackgroundView: UIView {
    var text: String? {
        get { label.text }
        set { label.text = newValue }
    }

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(label)

        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .body)
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: readableContentGuide.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
        ])
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
