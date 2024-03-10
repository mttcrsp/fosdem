import UIKit

struct EventAdditionsGroup {
  let title: String
  let image: UIImage?
  let items: [EventAdditionsItem]
}

struct EventAdditionsItem {
  let title: String
  let url: URL
}

final class EventAdditionsItemView: UIControl {
  var group: EventAdditionsGroup? {
    didSet { didChangeGroup() }
  }

  var item: EventAdditionsItem? {
    didSet { didChangeItem() }
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

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var isHighlighted: Bool {
    didSet { alpha = isHighlighted ? 0.5 : 1 }
  }

  private func didChangeItem() {
    accessibilityLabel = item?.title
    label.text = item?.title
  }

  private func didChangeGroup() {
    imageView.image = group?.image
  }
}

extension EventAdditionsGroup {
  init(attachments: [Attachment]) {
    image = UIImage(systemName: "arrow.down.circle")
    items = attachments.compactMap(EventAdditionsItem.init)
    title = L10n.Event.attachments
  }

  init(links: [Link]) {
    image = UIImage(systemName: "link")
    items = links.compactMap(EventAdditionsItem.init)
    title = L10n.Event.links
  }
}

extension EventAdditionsItem {
  init?(link: Link) {
    if let url = link.url, link.isAddition {
      self.init(title: link.name, url: url)
    } else {
      return nil
    }
  }

  init?(attachment: Attachment) {
    if let title = attachment.title {
      self.init(title: title, url: attachment.url)
    } else {
      return nil
    }
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
      L10n.Attachment.slides
    case .audio:
      L10n.Attachment.audio
    case .paper:
      L10n.Attachment.paper
    case .video:
      L10n.Attachment.video
    case .other:
      nil
    }
  }
}
