import UIKit

protocol TracksBackgroundViewDelegate: AnyObject {
    func backgroundView(_ backgroundView: TracksBackgroundView, didSelect section: Int)
}

final class TracksBackgroundView: UIView {
    weak var delegate: TracksBackgroundViewDelegate?

    var sectionTitles: [String] {
        get { indexView.titles }
        set { indexView.titles = newValue }
    }

    var sectionIndexWidth: CGFloat {
        layoutIfNeeded()
        return indexView.bounds.width
    }

    var showsEmptyMessage: Bool = false {
        didSet { didChangeShowsEmptyMessage() }
    }

    private var backgroundView = TableBackgroundView()
    private var indexView = IndexView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(indexView)
        addSubview(backgroundView)

        backgroundView.isHidden = true
        backgroundView.text = NSLocalizedString("search.empty", comment: "")
        indexView.addTarget(self, action: #selector(didChangeSectionIndex), for: .valueChanged)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        backgroundView.frame = bounds

        let indexViewFittingSize = indexView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        indexView.frame.size.height = bounds.height
        indexView.frame.size.width = indexViewFittingSize.width
        indexView.frame.origin.x = bounds.width - indexView.bounds.width
    }

    private func didChangeShowsEmptyMessage() {
        indexView.isHidden = showsEmptyMessage
        backgroundView.isHidden = !showsEmptyMessage
    }

    @objc private func didChangeSectionIndex() {
        if let section = indexView.selectedSectionIndex {
            delegate?.backgroundView(self, didSelect: section)
        }
    }
}
