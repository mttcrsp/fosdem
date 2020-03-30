import UIKit

final class BlueprintCollectionViewCell: UICollectionViewCell {
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with blueprint: Blueprint) {
        imageView.image = UIImage(named: blueprint.imageName)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = contentView.bounds.inset(by: layoutMargins)
    }
}
