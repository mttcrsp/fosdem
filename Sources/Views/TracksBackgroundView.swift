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

    private var indexView = IndexView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(indexView)
        indexView.translatesAutoresizingMaskIntoConstraints = false
        indexView.addTarget(self, action: #selector(didChangeSectionIndex), for: .valueChanged)

        NSLayoutConstraint.activate([
            indexView.topAnchor.constraint(equalTo: topAnchor),
            indexView.bottomAnchor.constraint(equalTo: bottomAnchor),
            indexView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 3),
        ])
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didChangeSectionIndex() {
        if let section = indexView.selectedSectionIndex {
            delegate?.backgroundView(self, didSelect: section)
        }
    }
}
