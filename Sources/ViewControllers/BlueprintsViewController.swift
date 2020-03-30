import UIKit

protocol BlueprintsViewControllerDelegate: AnyObject {
    func blueprintsViewController(_ blueprintsViewController: BlueprintsViewController, didDisplay blueprint: Blueprint)
}

final class BlueprintsViewController: UIViewController {
    weak var delegate: BlueprintsViewControllerDelegate?

    var building: Building? {
        didSet { didChangeBuilding() }
    }

    private lazy var backgroundView = TableBackgroundView()
    private lazy var collectionViewLayout = UICollectionViewFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(collectionView)
        view.preservesSuperviewLayoutMargins = false
        view.layoutMargins = .init(top: 8, left: 8, bottom: 8, right: 8)

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.backgroundColor = .clear
        collectionView.backgroundView = backgroundView
        collectionView.register(BlueprintCollectionViewCell.self, forCellWithReuseIdentifier: BlueprintCollectionViewCell.reuseIdentifier)

        collectionViewLayout.minimumLineSpacing = 0
        collectionViewLayout.scrollDirection = .horizontal
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
        collectionViewLayout.itemSize = view.bounds.size
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.flashScrollIndicators()
        scrollViewDidEndDecelerating(collectionView)
    }

    private func didChangeBuilding() {
        collectionView.reloadData()
        collectionView.flashScrollIndicators()
        scrollViewDidEndDecelerating(collectionView)
    }
}

extension BlueprintsViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        let count = building?.blueprints.count ?? 0

        if count == 0 {
            backgroundView.text = NSLocalizedString("map.blueprint.empty", comment: "")
        } else {
            backgroundView.text = nil
        }

        return count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BlueprintCollectionViewCell.reuseIdentifier, for: indexPath) as! BlueprintCollectionViewCell

        if let blueprint = building?.blueprints[indexPath.row] {
            cell.configure(with: blueprint)
        }

        return cell
    }

    func scrollViewDidEndDecelerating(_: UIScrollView) {
        guard let building = building else { return }

        let centerX = collectionView.bounds.midX
        let centerY = collectionView.bounds.midY
        let center = CGPoint(x: centerX, y: centerY)

        if let indexPath = collectionView.indexPathForItem(at: center) {
            let blueprint = building.blueprints[indexPath.item]
            delegate?.blueprintsViewController(self, didDisplay: blueprint)
        }
    }
}
