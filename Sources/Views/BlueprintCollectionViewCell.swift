import UIKit

final class BlueprintCollectionViewCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit

        contentView.addSubview(label)
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .headline)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with blueprint: Blueprint) {
        label.text = blueprint.title
        imageView.image = UIImage(named: blueprint.imageName)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        label.sizeToFit()
        label.frame.size.width = contentView.bounds.width - layoutMargins.left - layoutMargins.right
        label.frame.origin.x = layoutMargins.left
        label.frame.origin.y = layoutMargins.top

        imageView.frame.size.width = contentView.bounds.width - layoutMargins.left - layoutMargins.right
        imageView.frame.size.height = contentView.bounds.height - label.frame.maxY - layoutMargins.top - layoutMargins.bottom
        imageView.frame.origin.x = layoutMargins.left
        imageView.frame.origin.y = label.frame.maxY + layoutMargins.top
    }
}
