import UIKit

final class ImagesGenerator {
    final class Descriptor: NSObject {
        let color: UIColor, cornerRadius: CGFloat

        init(color: UIColor, cornerRadius: CGFloat = 0) {
            self.cornerRadius = cornerRadius
            self.color = color
        }
    }

    static let shared = ImagesGenerator()

    private var cache = NSCache<Descriptor, UIImage>()

    private init() {}

    func makeImage(for descriptor: Descriptor) -> UIImage? {
        if let image = cache.object(forKey: descriptor) {
            return image
        }

        let radius = descriptor.cornerRadius
        let size = CGSize(width: (radius * 2) + 1, height: (radius * 2) + 1)
        let rect = CGRect(origin: .zero, size: size)

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }

        let context = UIGraphicsGetCurrentContext()
        context?.addPath(UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath)
        context?.setFillColor(descriptor.color.cgColor)
        context?.fillPath()

        let image = UIGraphicsGetImageFromCurrentImageContext()
        let capInsets = UIEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        let resizableImage = image?.resizableImage(withCapInsets: capInsets)

        if let image = resizableImage {
            cache.setObject(image, forKey: descriptor)
        }

        return resizableImage
    }

    func removeAllImages() {
        cache.removeAllObjects()
    }
}

extension ImagesGenerator.Descriptor {
    override var hash: Int {
        color.hash ^ Int(cornerRadius)
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ImagesGenerator.Descriptor else { return false }
        return color == other.color && cornerRadius == other.cornerRadius
    }
}
