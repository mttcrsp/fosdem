import UIKit

enum MoreItem: CaseIterable {
    case years
    case speakers
    case history
    case devrooms
    case transportation
    case acknowledgements
}

final class MoreController: UINavigationController {
    private weak var speakersViewController: SpeakersViewController?

    var speakers: [Person] = []

    private let services: Services

    init(services: Services) {
        self.services = services
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        viewControllers = [makeMoreViewController()]
        setNavigationBarHidden(true, animated: false)
    }

    private func makeMoreViewController() -> MoreViewController {
        let moreViewController = MoreViewController()
        moreViewController.title = NSLocalizedString("more.title", comment: "")
        moreViewController.delegate = self
        return moreViewController
    }

    private func makeSpeakersViewController() -> SpeakersViewController {
        let speakersViewController = SpeakersViewController()
        speakersViewController.title = NSLocalizedString("speakers.title", comment: "")
        speakersViewController.hidesBottomBarWhenPushed = true
        speakersViewController.dataSource = self
        speakersViewController.delegate = self
        self.speakersViewController = speakersViewController

        if #available(iOS 11.0, *) {
            speakersViewController.navigationItem.largeTitleDisplayMode = .never
        }

        return speakersViewController
    }

    private func makeHistoryViewController() -> TextViewController {
        let historyViewController = TextViewController()
        historyViewController.title = NSLocalizedString("history.title", comment: "")
        historyViewController.text = NSLocalizedString("history.body", comment: "")
        historyViewController.hidesBottomBarWhenPushed = true
        return historyViewController
    }

    private func makeDevroomsViewController() -> TextViewController {
        let devroomsViewController = TextViewController()
        devroomsViewController.title = NSLocalizedString("devrooms.title", comment: "")
        devroomsViewController.text = NSLocalizedString("devrooms.body", comment: "")
        devroomsViewController.hidesBottomBarWhenPushed = true
        return devroomsViewController
    }
}

extension MoreController: MoreViewControllerDelegate {
    func moreViewController(_ moreViewController: MoreViewController, didSelect item: MoreItem) {
        switch item {
        case .years: break
        case .transportation: break
        case .acknowledgements: break
        case .speakers: speakersTapped(in: moreViewController)
        case .history: moreViewController.show(makeHistoryViewController(), sender: nil)
        case .devrooms: moreViewController.show(makeDevroomsViewController(), sender: nil)
        }
    }

    private func speakersTapped(in moreViewController: MoreViewController) {
        moreViewController.show(makeSpeakersViewController(), sender: nil)

        services.persistenceService.people { result in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case .failure:
                    self?.popToRootViewController(animated: true)
                case let .success(speakers):
                    self?.speakers = speakers
                    self?.speakersViewController?.reloadData()
                }
            }
        }
    }
}

extension MoreController: SpeakersViewControllerDelegate, SpeakersViewControllerDataSource {
    func speakersViewController(_ speakersViewController: SpeakersViewController, didSelect person: Person) {
        print(#function, person, speakersViewController)
    }
}

extension MoreController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated _: Bool) {
        navigationController.setNavigationBarHidden(viewController is MoreViewController, animated: true)
    }
}
