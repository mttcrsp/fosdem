import UIKit

final class LabeledSegmentedControl: UIControl {
    var title: String? {
        get { label.text }
        set { label.text = newValue }
    }

    var selectedSegmentIndex: Int? {
        get { segmentedControl.selectedSegmentIndex }
        set { segmentedControl.selectedSegmentIndex = newValue }
    }

    private let label = UILabel()
    private let segmentedControl = SegmentedControl()

    override init(frame: CGRect) {
        super.init(frame: frame)

        label.font = .preferredFont(for: .title)

        for subview in [label, segmentedControl] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subview)
        }

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            label.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),

            segmentedControl.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 16),
            segmentedControl.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            segmentedControl.leadingAnchor.constraint(equalTo: leadingAnchor),
            segmentedControl.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        segmentedControl.contentInset.left = layoutMarginsGuide.layoutFrame.minX
        segmentedControl.contentInset.right = bounds.width - layoutMarginsGuide.layoutFrame.maxX
    }

    func insertSegment(withTitle title: String?, at segment: Int, animated: Bool) {
        segmentedControl.insertSegment(withTitle: title, at: segment, animated: animated)
    }

    override func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        segmentedControl.addTarget(target, action: action, for: controlEvents)
    }
}
