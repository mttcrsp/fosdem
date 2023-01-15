import UIKit

class TextViewController: UIViewController {
  var attributedText: NSAttributedString? {
    get { textView.attributedText }
    set { textView.attributedText = newValue }
  }

  var accessibilityIdentifier: String? {
    get { textView.accessibilityIdentifier }
    set { textView.accessibilityIdentifier = newValue }
  }

  private lazy var textView = UITextView()

  private var preferredFont: UIFont {
    .fos_preferredFont(forTextStyle: .body)
  }

  override func loadView() {
    view = textView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    textView.isEditable = false
    textView.font = preferredFont
    textView.backgroundColor = .fos_systemGroupedBackground
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    let verticalInset: CGFloat = 20
    let horizontalInset = max(10, textView.readableContentGuide.layoutFrame.minX)

    textView.textContainerInset.top = verticalInset
    textView.textContainerInset.bottom = verticalInset
    textView.textContainerInset.left = horizontalInset
    textView.textContainerInset.right = horizontalInset
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
      textView.font = preferredFont
    }
  }
}
