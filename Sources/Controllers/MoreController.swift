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
        moreViewController.title = NSLocalizedString("More", comment: "")
        moreViewController.delegate = self
        return moreViewController
    }

    private func makeSpeakersViewController() -> SpeakersViewController {
        let speakersViewController = SpeakersViewController()
        speakersViewController.title = NSLocalizedString("Speakers", comment: "")
        speakersViewController.hidesBottomBarWhenPushed = true
        speakersViewController.dataSource = self
        speakersViewController.delegate = self
        self.speakersViewController = speakersViewController

        if #available(iOS 11.0, *) {
            speakersViewController.navigationItem.largeTitleDisplayMode = .never
        }

        return speakersViewController
    }
}

extension MoreController: MoreViewControllerDelegate {
    func moreViewController(_ moreViewController: MoreViewController, didSelect item: MoreItem) {
        switch item {
        case .years: break
        case .speakers: speakersTapped(in: moreViewController)
        case .history: break
        case .devrooms: break
        case .transportation: break
        case .acknowledgements: break
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
        switch viewController {
        case _ as MoreViewController: navigationController.setNavigationBarHidden(true, animated: true)
        case _ as SpeakersViewController: navigationController.setNavigationBarHidden(false, animated: true)
        default: break
        }
    }
}
