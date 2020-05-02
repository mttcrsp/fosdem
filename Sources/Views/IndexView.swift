import UIKit

final class IndexView: UIControl {
    var titles: [String] = [] {
        didSet { didChangeTitles() }
    }

    var selectedSectionTitle: String? {
        didSet { didChangeSelectedTitle(from: oldValue, to: selectedSectionTitle) }
    }

    var selectedSectionIndex: Int? {
        if let title = selectedSectionTitle {
            return titles.firstIndex(of: title)
        } else {
            return nil
        }
    }

    private let textView = UITextView()
    private lazy var feedbackGenerator = UISelectionFeedbackGenerator()

    override init(frame: CGRect) {
        super.init(frame: frame)

        textView.isEditable = false
        textView.isSelectable = false
        textView.isScrollEnabled = false
        textView.textAlignment = .center
        textView.backgroundColor = .clear
        textView.font = .boldSystemFont(ofSize: 12)
        textView.isUserInteractionEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textView)

        isAccessibilityElement = true
        accessibilityTraits = .adjustable
        accessibilityLabel = NSLocalizedString("ui.sectionindex", comment: "")

        NSLayoutConstraint.activate([
            textView.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            textView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
        ])
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func accessibilityDecrement() {
        super.accessibilityDecrement()

        guard let index = selectedSectionIndex else {
            selectedSectionTitle = titles.first
            return
        }

        if titles.indices.contains(index + 1) {
            selectedSectionTitle = titles[index + 1]
        }
    }

    override func accessibilityIncrement() {
        super.accessibilityIncrement()

        if let index = selectedSectionIndex, titles.indices.contains(index - 1) {
            selectedSectionTitle = titles[index - 1]
        }
    }

    override func accessibilityElementDidLoseFocus() {
        super.accessibilityElementDidLoseFocus()
        selectedSectionTitle = nil
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        textView.textColor = tintColor
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        didReceiveTouches(touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        didReceiveTouches(touches)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        didStopReceivingTouches()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        didStopReceivingTouches()
    }

    private func didReceiveTouches(_ touches: Set<UITouch>) {
        guard let touch = touches.first else { return }

        // Centering the point allows selection to be independent from the width
        // of a given glyph. Without this, selecting an 'I' would be more
        // difficult than selecting an 'O'.
        let characterPoint = touch.location(in: textView)
        let characterPointCentered = CGPoint(x: textView.bounds.midX, y: characterPoint.y)
        let characterIndex = textView.layoutManager.characterIndex(for: characterPointCentered, in: textView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        selectedSectionTitle = String(Array(textView.text)[characterIndex])
    }

    private func didStopReceivingTouches() {
        // The user may tap a given character x and then tap it again. Not
        // clearing the selected title once processing of touches stops causes
        // only one event to be dispatched when we want two separate events for
        // these separate interactions.
        selectedSectionTitle = nil
    }

    private func didChangeSelectedTitle(from oldValue: String?, to newValue: String?) {
        accessibilityValue = newValue?.lowercased()

        // When dragging the system may generate multiple touch events all
        // within the bounds of a given character. However we do not want to
        // dispatch change events for the same selected title during a drag.
        if let newValue = newValue, newValue != oldValue {
            sendActions(for: .valueChanged)
            feedbackGenerator.selectionChanged()
        }
    }

    private func didChangeTitles() {
        textView.text = titles.joined(separator: "\n")
    }
}
