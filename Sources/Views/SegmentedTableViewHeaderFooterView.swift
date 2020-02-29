import UIKit

final class SegmentedTableViewHeaderFooterView: UITableViewHeaderFooterView {
    var selectedSegmentIndex: Int? {
        get { segmentedControl.selectedSegmentIndex }
        set { segmentedControl.selectedSegmentIndex = newValue }
    }

    private let segmentedControl = SegmentedControl()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        backgroundView = UIView()
        backgroundView?.backgroundColor = .fos_systemBackground

        contentView.addSubview(segmentedControl)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            segmentedControl.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            segmentedControl.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
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

    func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        segmentedControl.addTarget(target, action: action, for: controlEvents)
    }
}
