import CoreImage
import UIKit

extension UIImage {
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

extension UIImage {
  static let filter: UIImage? = {
    if #available(iOS 15.0, *) {
      UIImage(systemName: "line.3.horizontal.decrease")
    } else {
      UIImage(systemName: "line.horizontal.3.decrease")
    }
  }()
}
