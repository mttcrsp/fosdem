import UIKit

final class EventAttachmentView: UIControl {
  var attachment: Attachment? {
    didSet { didChangeAttachment() }
  }

  private let label = UILabel()
  private let imageView = UIImageView()

  override init(frame: CGRect) {
    super.init(frame: frame)

    accessibilityTraits = .link
    isAccessibilityElement = true

    label.numberOfLines = 0
    label.adjustsFontForContentSizeCategory = true
    label.font = .fos_preferredFont(forTextStyle: .body, withSymbolicTraits: [.traitItalic])

    imageView.contentMode = .center
    imageView.image = .fos_systemImage(withName: "arrow.down.circle")

    for subview in [imageView, label] {
      subview.translatesAutoresizingMaskIntoConstraints = false
      addSubview(subview)
    }

    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: topAnchor),
      label.bottomAnchor.constraint(equalTo: bottomAnchor),
      label.leadingAnchor.constraint(equalTo: leadingAnchor),
      label.trailingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: -10),

      imageView.widthAnchor.constraint(equalToConstant: 20),
      imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor),
      imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
      imageView.centerYAnchor.constraint(equalTo: label.centerYAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  class func canDisplay(_ attachment: Attachment) -> Bool {
    attachment.title != nil
  }

  override var isHighlighted: Bool {
    didSet { alpha = isHighlighted ? 0.5 : 1 }
  }

  private func didChangeAttachment() {
    accessibilityLabel = attachment?.title
    label.text = attachment?.title
  }
}

private extension Attachment {
  var title: String? {
    switch (name, type.title) {
    case (nil, nil):
      return nil
    case (let value?, nil), (nil, let value?):
      return value
    case let (name?, type?):
      let lowercaseName = name.lowercased()
      let lowercaseType = type.lowercased()
      if lowercaseName.contains(lowercaseType) {
        return name
      } else {
        return "\(name) (\(type))"
      }
    }
  }
}

private extension AttachmentType {
  var title: String? {
    switch self {
    case .slides:
      return L10n.Attachment.slides
    case .audio:
      return L10n.Attachment.audio
    case .paper:
      return L10n.Attachment.paper
    case .video:
      return L10n.Attachment.video
    case .other:
      return nil
    }
  }
}
