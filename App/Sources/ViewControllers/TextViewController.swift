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

  override func loadView() {
    view = textView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    textView.isEditable = false
    textView.backgroundColor = .systemGroupedBackground
    textView.adjustsFontForContentSizeCategory = true
    textView.textContainer.lineFragmentPadding = 0
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
}
