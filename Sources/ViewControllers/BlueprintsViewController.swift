import UIKit

protocol BlueprintViewControllerDelegate: AnyObject {
    func blueprintViewControllerDidTapDismiss(_ blueprintViewController: BlueprintsViewController)
    func blueprintViewControllerDidTapFullscreen(_ blueprintViewController: BlueprintsViewController)
}

final class BlueprintsViewController: UIViewController {
    weak var delegate: BlueprintViewControllerDelegate?

    var building: Building? {
        didSet { didChangeBuilding() }
    }

    private lazy var dismissButton = UIButton()
    private lazy var fullscreenButton = UIButton()
    private lazy var backgroundView = TableBackgroundView()
    private lazy var collectionViewLayout = UICollectionViewFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.backgroundColor = .clear
        collectionView.backgroundView = backgroundView
        collectionView.register(BlueprintCollectionViewCell.self, forCellWithReuseIdentifier: BlueprintCollectionViewCell.reuseIdentifier)

        collectionViewLayout.minimumLineSpacing = 0
        collectionViewLayout.scrollDirection = .horizontal

        let dismissImageName = "xmark"
        let dismissImage: UIImage?
        if #available(iOS 13.0, *) {
            dismissImage = UIImage(systemName: dismissImageName)
        } else {
            dismissImage = UIImage(named: dismissImageName)
        }

        let fullscreenImageName = "arrow.up.left.and.arrow.down.right"
        let fullscreenImage: UIImage?
        if #available(iOS 13.0, *) {
            fullscreenImage = UIImage(systemName: fullscreenImageName)
        } else {
            fullscreenImage = UIImage(named: fullscreenImageName)
        }

        let dismissAction = #selector(didTapDismiss)
        dismissButton.setImage(dismissImage, for: .normal)
        dismissButton.addTarget(self, action: dismissAction, for: .touchUpInside)

        let fullscreenAction = #selector(didTapFullscreen)
        fullscreenButton.setImage(fullscreenImage, for: .normal)
        fullscreenButton.addTarget(self, action: fullscreenAction, for: .touchUpInside)

        for button in [dismissButton, fullscreenButton] {
            button.layer.borderColor = UIColor.black.cgColor
            button.layer.borderWidth = 1
            button.layer.cornerRadius = 4
            button.contentMode = .center
        }

        view.addSubview(collectionView)
        view.addSubview(dismissButton)
        view.addSubview(fullscreenButton)
        view.preservesSuperviewLayoutMargins = false
        view.layoutMargins = .init(top: 8, left: 8, bottom: 8, right: 8)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let buttonSize = CGSize(width: 24, height: 24)

        fullscreenButton.frame.size = buttonSize
        fullscreenButton.frame.origin.x = view.layoutMargins.left
        fullscreenButton.frame.origin.y = view.layoutMargins.top

        dismissButton.frame.size = buttonSize
        dismissButton.frame.origin.x = view.bounds.width - buttonSize.width - view.layoutMargins.right
        dismissButton.frame.origin.y = view.layoutMargins.top

        collectionView.frame = view.bounds
        collectionViewLayout.itemSize = view.bounds.size
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.flashScrollIndicators()
    }

    @objc private func didTapDismiss() {
        delegate?.blueprintViewControllerDidTapDismiss(self)
    }

    @objc private func didTapFullscreen() {
        delegate?.blueprintViewControllerDidTapFullscreen(self)
    }

    private func didChangeBuilding() {
        collectionView.reloadData()
        collectionView.flashScrollIndicators()
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
}
