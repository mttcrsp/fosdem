import UIKit

final class SegmentedControl: UIControl {
    var selectedSegmentIndex: Int? {
        get { _selectedSegmentIndex() }
        set { _setSelectedSegmentIndex(newValue) }
    }

    var contentInset: UIEdgeInsets {
        get { scrollView.contentInset }
        set { scrollView.contentInset = newValue }
    }

    private let stackView = UIStackView()
    private let scrollView = UIScrollView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(scrollView)

        scrollView.addSubview(stackView)
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        stackView.spacing = 10
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.heightAnchor.constraint(equalTo: stackView.heightAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
        ])
    }

    convenience init(titles: [String]) {
        self.init()

        for (index, title) in titles.enumerated() {
            insertSegment(withTitle: title, at: index, animated: false)
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var buttons: [RoundedButton] {
        stackView.arrangedSubviews.compactMap { subview in subview as? RoundedButton }
    }

    var numberOfSegments: Int {
        stackView.arrangedSubviews.count
    }

    func insertSegment(withTitle title: String?, at segment: Int, animated: Bool) {
        UIView.perform(withAnimations: animated) { [weak self] in
            if let self = self {
                self.stackView.insertArrangedSubview(self.makeButton(withTitle: title), at: segment)
            }
        }
    }

    func removeSegment(at segment: Int, animated: Bool) {
        let subview = stackView.arrangedSubviews[segment]
        UIView.perform(withAnimations: animated) { [weak self] in
            self?.stackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
    }

    func removeAllSegments() {
        let subviews = stackView.arrangedSubviews
        for subview in subviews {
            stackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
    }

    func setTitle(_ title: String?, forSegmentAt segment: Int) {
        buttons[segment].setTitle(title, for: .normal)
    }

    func titleForSegment(at segment: Int) -> String? {
        buttons[segment].title(for: .normal)
    }

    func setEnabled(_ enabled: Bool, forSegmentAt segment: Int) {
        buttons[segment].isEnabled = enabled
    }

    func isEnabledForSegment(at segment: Int) -> Bool {
        buttons[segment].isEnabled
    }

    func setSelected(_ selected: Bool, forSegmentAt segment: Int) {
        for (index, button) in buttons.enumerated() {
            button.isSelected = index == segment && selected
        }
    }

    func isSelectedForSegment(at segment: Int) -> Bool {
        buttons[segment].isSelected
    }

    @objc private func didTapButton(_ sender: RoundedButton) {
        guard let index = buttons.firstIndex(of: sender) else {
            return assertionFailure("Unexpected selection event received from sender \(sender) not managed by receiver \(self).")
        }

        if index != selectedSegmentIndex {
            setSelected(true, forSegmentAt: index)
            sendActions(for: .valueChanged)
        }
    }

    private func makeButton(withTitle title: String?) -> RoundedButton {
        let button = RoundedButton()
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        return button
    }

    private func _selectedSegmentIndex() -> Int? {
        buttons.firstIndex { button in button.isSelected }
    }

    private func _setSelectedSegmentIndex(_ index: Int?) {
        if let index = index {
            setSelected(true, forSegmentAt: index)
        } else if let selectedSegmentIndex = selectedSegmentIndex {
            setSelected(false, forSegmentAt: selectedSegmentIndex)
        }
    }
}

private extension UIView {
    static func perform(withAnimations animated: Bool, block: @escaping () -> Void) {
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: block)
        } else {
            UIView.performWithoutAnimation(block)
        }
    }
}
