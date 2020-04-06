import UIKit

final class RoundedButtonTableViewCell: UITableViewCell {
    let button = RoundedButton()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        contentView.addSubview(button)

        button.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            button.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
        ])
    }
}
