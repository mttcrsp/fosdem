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
  static func fos_systemImage(withName name: String) -> UIImage? {
    if #available(iOS 13.0, *) {
      return UIImage(systemName: name)
    } else {
      return UIImage(named: name)
    }
  }
}
