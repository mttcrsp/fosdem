import UIKit

protocol TracksViewControllerDataSource: AnyObject {
    func numberOfSections(in tracksViewController: TracksViewController) -> Int
    func tracksViewController(_ tracksViewController: TracksViewController, numberOfTracksIn section: Int) -> Int
    func tracksViewController(_ tracksViewController: TracksViewController, trackAt indexPath: IndexPath) -> Track
}

protocol TracksViewControllerIndexDataSource: AnyObject {
    func sectionIndexTitles(in tracksViewController: TracksViewController) -> [String]
    func tracksViewController(_ tracksViewController: TracksViewController, titleForSectionAt section: Int) -> String?
}

protocol TracksViewControllerFavoritesDataSource: AnyObject {
    func tracksViewController(_ tracksViewController: TracksViewController, canFavorite track: Track) -> Bool
}

protocol TracksViewControllerDelegate: AnyObject {
    func tracksViewController(_ tracksViewController: TracksViewController, didSelect track: Track)
}

protocol TracksViewControllerIndexDelegate: AnyObject {
    func tracksViewController(_ tracksViewController: TracksViewController, didSelect section: Int)
}

protocol TracksViewControllerFavoritesDelegate: AnyObject {
    func tracksViewController(_ tracksViewController: TracksViewController, didFavorite track: Track)
    func tracksViewController(_ tracksViewController: TracksViewController, didUnfavorite track: Track)
}

class TracksViewController: UITableViewController {
    weak var dataSource: TracksViewControllerDataSource?
    weak var delegate: TracksViewControllerDelegate?

    weak var indexDataSource: TracksViewControllerIndexDataSource?
    weak var indexDelegate: TracksViewControllerIndexDelegate?

    weak var favoritesDataSource: TracksViewControllerFavoritesDataSource?
    weak var favoritesDelegate: TracksViewControllerFavoritesDelegate?

    private lazy var feedbackGenerator = UISelectionFeedbackGenerator()

    func reloadData() {
        if isViewLoaded {
            tableView.reloadData()
        }
    }

    func scrollToRow(at indexPath: IndexPath, at scrollPosition: UITableView.ScrollPosition, animated: Bool) {
        tableView.scrollToRow(at: indexPath, at: scrollPosition, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 44
        tableView.estimatedSectionHeaderHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = indexDataSource == nil
        tableView.sectionHeaderHeight = indexDataSource == nil ? 0 : UITableView.automaticDimension
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
        tableView.register(LabelTableHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: LabelTableHeaderFooterView.reuseIdentifier)
    }

    override func numberOfSections(in _: UITableView) -> Int {
        dataSource?.numberOfSections(in: self) ?? 0
    }

    override func sectionIndexTitles(for _: UITableView) -> [String]? {
        indexDataSource?.sectionIndexTitles(in: self)
    }

    override func tableView(_: UITableView, sectionForSectionIndexTitle _: String, at section: Int) -> Int {
        // HACK: UITableView only supports using section index titles pointing
        // to the first element of a given section. However here I want the
        // indices to point to arbitrary index paths. In order to achieve this
        // here I am always returning the first section as the target section
        // for handling by UITableView and preventing content offset updates by
        // replacing -[UIScrollView setContentOffset:] with an empty
        // implementation. Clients of TracksViewController delegate API will
        // then be able to apply their custom logic to select a given index
        // path. The only thing that this implementation is missing when
        // compared with the original table view one is handling of prevention
        // of unnecessary haptic feedback responses when no movement should be
        // performed.
        let originalMethod = class_getInstanceMethod(UIScrollView.self, #selector(setter: UIScrollView.contentOffset))
        let swizzledMethod = class_getInstanceMethod(UIScrollView.self, #selector(setter: UIScrollView.fos_contentOffset))
        if let method1 = originalMethod, let method2 = swizzledMethod {
            method_exchangeImplementations(method1, method2)
            OperationQueue.main.addOperation { [weak self] in
                method_exchangeImplementations(method1, method2)

                if let self = self {
                    self.feedbackGenerator.selectionChanged()
                    self.indexDelegate?.tracksViewController(self, didSelect: section)
                }
            }
        }

        return 0
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: LabelTableHeaderFooterView.reuseIdentifier) as! LabelTableHeaderFooterView
        view.text = indexDataSource?.tracksViewController(self, titleForSectionAt: section)
        view.font = .fos_preferredFont(forTextStyle: .headline)
        view.textColor = .fos_label
        return view
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource?.tracksViewController(self, numberOfTracksIn: section) ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
        if let track = dataSource?.tracksViewController(self, trackAt: indexPath) {
            cell.configure(with: track)
        }
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let track = dataSource?.tracksViewController(self, trackAt: indexPath) {
            delegate?.tracksViewController(self, didSelect: track)
        }
    }

    override func tableView(_: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let dataSource = dataSource, let favoritesDataSource = favoritesDataSource else { return nil }

        let track = dataSource.tracksViewController(self, trackAt: indexPath)

        if favoritesDataSource.tracksViewController(self, canFavorite: track) {
            return [.favorite { [weak self] _ in self?.didFavorite(track) }]
        } else {
            return [.unfavorite { [weak self] _ in self?.didUnfavorite(track) }]
        }
    }

    @available(iOS 11.0, *)
    override func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let dataSource = dataSource, let favoritesDataSource = favoritesDataSource else { return nil }

        let track = dataSource.tracksViewController(self, trackAt: indexPath)

        let actions: [UIContextualAction]
        if favoritesDataSource.tracksViewController(self, canFavorite: track) {
            actions = [makeFavoriteAction(for: track)]
        } else {
            actions = [makeUnfavoriteAction(for: track)]
        }
        return UISwipeActionsConfiguration(actions: actions)
    }

    @available(iOS 11.0, *)
    private func makeFavoriteAction(for track: Track) -> UIContextualAction {
        let handler: UIContextualAction.Handler = { [weak self] _, _, completionHandler in
            self?.didFavorite(track)
            completionHandler(true)
        }

        let actionImage = UIImage.fos_systemImage(withName: "star.fill")
        let actionTitle = NSLocalizedString("favorite", comment: "")
        let action = UIContextualAction(style: .normal, title: actionTitle, handler: handler)
        action.backgroundColor = .systemBlue
        action.image = actionImage
        return action
    }

    @available(iOS 11.0, *)
    private func makeUnfavoriteAction(for track: Track) -> UIContextualAction {
        let handler: UIContextualAction.Handler = { [weak self] _, _, completionHandler in
            self?.didUnfavorite(track)
            completionHandler(true)
        }

        let actionImage = UIImage.fos_systemImage(withName: "star.slash.fill")
        let actionTitle = NSLocalizedString("unfavorite", comment: "")
        let action = UIContextualAction(style: .destructive, title: actionTitle, handler: handler)
        action.image = actionImage
        return action
    }

    private func didFavorite(_ track: Track) {
        favoritesDelegate?.tracksViewController(self, didFavorite: track)
    }

    private func didUnfavorite(_ track: Track) {
        favoritesDelegate?.tracksViewController(self, didUnfavorite: track)
    }
}

private extension UITableViewCell {
    func configure(with track: Track) {
        textLabel?.numberOfLines = 0
        textLabel?.text = track.name
        textLabel?.font = .fos_preferredFont(forTextStyle: .body)
        accessoryType = .disclosureIndicator
    }
}

@objc private extension UIScrollView {
    var fos_contentOffset: CGPoint {
        get { .zero }
        set {}
    }
}
