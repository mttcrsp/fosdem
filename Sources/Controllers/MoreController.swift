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

    private(set) var speakers: [Person] = []
    private(set) var acknowledgements: [Acknowledgement] = []

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

    private func makeAcknowledgementsViewController() -> AcknowledgementsViewController {
        let acknowledgementsViewController = AcknowledgementsViewController()
        acknowledgementsViewController.title = NSLocalizedString("acknowledgements.title", comment: "")
        acknowledgementsViewController.hidesBottomBarWhenPushed = true
        acknowledgementsViewController.dataSource = self
        acknowledgementsViewController.delegate = self
        return acknowledgementsViewController
    }

    private func makeLicenseViewController(for acknowledgement: Acknowledgement, withLicense license: String) -> TextViewController {
        let licenseViewController = TextViewController()
        licenseViewController.title = acknowledgement
        licenseViewController.text = license
        return licenseViewController
    }
}

extension MoreController: MoreViewControllerDelegate {
    func moreViewController(_ moreViewController: MoreViewController, didSelect item: MoreItem) {
        switch item {
        case .years: break
        case .transportation: break
        case .speakers: speakersTapped(in: moreViewController)
        case .acknowledgements: acknowledgementsTapped(in: moreViewController)
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

    private func acknowledgementsTapped(in moreViewController: MoreViewController) {
        DispatchQueue.global().async { [weak self, weak moreViewController] in
            let acknowledgements = self?.services.acknowledgementsService.loadAcknowledgements()

            DispatchQueue.main.async {
                guard let self = self, let moreViewController = moreViewController else { return }

                if let acknowledgements = acknowledgements {
                    self.acknowledgements = acknowledgements
                    moreViewController.show(self.makeAcknowledgementsViewController(), sender: nil)
                } else {
                    moreViewController.present(ErrorController(), animated: true)
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

extension MoreController: AcknowledgementsViewControllerDataSource, AcknowledgementsViewControllerDelegate {
    func acknowledgementsViewController(_ acknowledgementsViewController: AcknowledgementsViewController, didSelect acknowledgement: Acknowledgement) {
        DispatchQueue.global().async { [weak self, weak acknowledgementsViewController] in
            guard let self = self else { return }

            let acknowledgementsService = self.services.acknowledgementsService
            var license = acknowledgementsService.loadLicense(for: acknowledgement)
            if let licence = license {
                license = acknowledgementsService.makeFormattedLicense(fromLicense: licence)
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self, let acknowledgementsViewController = acknowledgementsViewController else { return }

                if let license = license {
                    let licenseViewController = self.makeLicenseViewController(for: acknowledgement, withLicense: license)
                    acknowledgementsViewController.show(licenseViewController, sender: nil)
                } else {
                    let errorViewController = ErrorController()
                    acknowledgementsViewController.present(errorViewController, animated: true)
                }
            }
        }
    }
}
