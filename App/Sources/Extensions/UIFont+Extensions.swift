import UIKit

extension UIFont {
  class func fos_preferredFont(forTextStyle style: UIFont.TextStyle, withSymbolicTraits traits: UIFontDescriptor.SymbolicTraits = []) -> UIFont {
    let descriptorOriginal = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
    let descriptor = descriptorOriginal.withSymbolicTraits(traits) ?? descriptorOriginal
    return UIFont(descriptor: descriptor, size: 0)
  }
}

final class FontSampleViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let regularLabel = UILabel()
    regularLabel.text = "Regular"
    regularLabel.font = .fos_preferredFont(forTextStyle: .body)
    
    let boldLabel = UILabel()
    boldLabel.text = "Bold"
    boldLabel.font = .fos_preferredFont(forTextStyle: .body, withSymbolicTraits: .traitBold)
    
    let italicLabel = UILabel()
    italicLabel.text = "Italic"
    italicLabel.font = .fos_preferredFont(forTextStyle: .body, withSymbolicTraits: .traitItalic)
    
    let monoSpaceLabel = UILabel()
    monoSpaceLabel.text = "MonoSpace"
    monoSpaceLabel.font = .fos_preferredFont(forTextStyle: .body, withSymbolicTraits: .traitMonoSpace)
    
    let stackView = UIStackView(arrangedSubviews: [regularLabel, boldLabel, italicLabel, monoSpaceLabel])
    stackView.axis = .vertical
    stackView.spacing = 16
    stackView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stackView)
    
    NSLayoutConstraint.activate([
      stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }
}
