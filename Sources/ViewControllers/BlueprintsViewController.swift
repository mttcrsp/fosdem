import UIKit

protocol BlueprintsViewControllerDelegate: AnyObject {
    func blueprintsViewControllerDidTapDismiss(_ blueprintsViewController: BlueprintsViewController)
    func blueprintsViewControllerDidSelectBlueprint(_ blueprintsViewController: BlueprintsViewController)
}

protocol BlueprintsViewControllerFullscreenDelegate: AnyObject {
    func blueprintsViewControllerDidTapFullscreen(_ blueprintViewController: BlueprintsViewController)
}

final class BlueprintsViewController: UIViewController {
    weak var fullscreenDelegate: BlueprintsViewControllerFullscreenDelegate?
    weak var delegate: BlueprintsViewControllerDelegate?

    var building: Building? {
        didSet { didChangeBuilding() }
    }

    private lazy var backgroundView = TableBackgroundView()
    private lazy var collectionViewLayout = UICollectionViewFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)

    private lazy var dismissButton: UIBarButtonItem = {
        let dismissImageName = "xmark"
        let dismissAction = #selector(didTapDismiss)
        return makeBarButtonItem(forAction: dismissAction, withImageNamed: dismissImageName)
    }()

    private lazy var fullscreenButton: UIBarButtonItem = {
        let fullscreenAction = #selector(didTapFullscreen)
        let fullscreenImageName = "arrow.up.left.and.arrow.down.right"
        return makeBarButtonItem(forAction: fullscreenAction, withImageNamed: fullscreenImageName)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = dismissButton

        view.addSubview(collectionView)
        view.backgroundColor = .fos_systemBackground
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
    }

    private func didChangeBuilding() {
        collectionView.reloadData()
        collectionView.flashScrollIndicators()
        didChangeVisibleBlueprint()
    }

    private func didChangeVisibleBlueprint() {
        guard let building = building else { return }

        let centerX = collectionView.bounds.midX
        let centerY = collectionView.bounds.midY
        let center = CGPoint(x: centerX, y: centerY)

        if let indexPath = collectionView.indexPathForItem(at: center) {
            title = building.blueprints[indexPath.item].title
            navigationItem.leftBarButtonItem = fullscreenDelegate == nil ? nil : fullscreenButton
        } else if let blueprint = building.blueprints.first {
            title = blueprint.title
            navigationItem.leftBarButtonItem = fullscreenDelegate == nil ? nil : fullscreenButton
        } else {
            title = nil
            navigationItem.leftBarButtonItem = nil
        }
    }

    @objc private func didTapDismiss() {
        delegate?.blueprintsViewControllerDidTapDismiss(self)
    }

    @objc private func didTapFullscreen() {
        fullscreenDelegate?.blueprintsViewControllerDidTapFullscreen(self)
    }

    private func makeBarButtonItem(forAction action: Selector, withImageNamed imageName: String) -> UIBarButtonItem {
        let image: UIImage?
        if #available(iOS 13.0, *) {
            image = UIImage(systemName: imageName)
        } else {
            image = UIImage(named: imageName)
        }
        return UIBarButtonItem(image: image, style: .plain, target: self, action: action)
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

    func collectionView(_: UICollectionView, didSelectItemAt _: IndexPath) {
        delegate?.blueprintsViewControllerDidSelectBlueprint(self)
    }

    func scrollViewDidEndDecelerating(_: UIScrollView) {
        didChangeVisibleBlueprint()
    }
}
