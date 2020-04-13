import CoreImage
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
        let blueprintImage = UIImage(named: blueprint.imageName)

        if #available(iOS 12.0, *), traitCollection.userInterfaceStyle == .dark {
            imageView.image = blueprintImage?.inverted
        } else {
            imageView.image = blueprintImage
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 12.0, *), traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            imageView.image = imageView.image?.inverted
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = contentView.bounds.inset(by: layoutMargins)
    }
}

private extension UIImage {
    var inverted: UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }

        let filter = CIFilter(name: "CIColorInvert")
        filter?.setDefaults()
        filter?.setValue(ciImage, forKey: kCIInputImageKey)

        let context = CIContext(options: nil)
        if let output = filter?.outputImage, let copy = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: copy, scale: scale, orientation: .up)
        } else {
            return nil
        }
    }
}
