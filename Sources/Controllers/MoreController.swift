import UIKit

final class MoreController: UISplitViewController {
    private weak var moreViewController: MoreViewController?

    private(set) var acknowledgements: [Acknowledgement] = []
    private var years: [String] = []

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

        let moreViewController = makeMoreViewController()
        let moreNavigationController = UINavigationController(rootViewController: moreViewController)

        if #available(iOS 11.0, *) {
            moreNavigationController.navigationBar.prefersLargeTitles = true
        }

        viewControllers = [moreNavigationController]

        if traitCollection.horizontalSizeClass == .regular, let section = MoreSection.allCases.first, let item = section.items.first, let info = item.info {
            showInfoViewController(withTitle: item.title, for: info)
        }
    }
}

extension MoreController: MoreViewControllerDelegate {
    func moreViewController(_ moreViewController: MoreViewController, didSelect item: MoreItem) {
        switch item {
        #if DEBUG
            case .time: moreViewControllerDidSelectTime(moreViewController)
        #endif
        case .code: moreViewControllerDidSelectCode(moreViewController)
        case .years: moreViewControllerDidSelectYears(moreViewController)
        case .history: moreViewControllerDidSelectHistory(moreViewController)
        case .devrooms: moreViewControllerDidSelectDevrooms(moreViewController)
        case .transportation: moreViewControllerDidSelectTransportation(moreViewController)
        case .acknowledgements: moreViewControllerDidSelectAcknowledgements(moreViewController)
        }
    }

    private func moreViewControllerDidSelectYears(_ moreViewController: MoreViewController) {
        services.yearsService.loadYears { years in
            DispatchQueue.main.async { [weak self, weak moreViewController] in
                if let self = self {
                    self.years = years
                    moreViewController?.show(self.makeYearsViewController(), sender: nil)
                }
            }
        }
    }

    private func moreViewControllerDidSelectCode(_ moreViewController: MoreViewController) {
        if let url = URL(string: "https://www.github.com/mttcrsp/fosdem") {
            UIApplication.shared.open(url) { [weak moreViewController] _ in
                moreViewController?.deselectSelectedRow(animated: true)
            }
        }
    }

    private func moreViewControllerDidSelectHistory(_: MoreViewController) {
        showInfoViewController(withTitle: MoreItem.history.title, for: .history)
    }

    private func moreViewControllerDidSelectDevrooms(_: MoreViewController) {
        showInfoViewController(withTitle: MoreItem.devrooms.title, for: .devrooms)
    }

    private func moreViewControllerDidSelectTransportation(_ moreViewController: MoreViewController) {
        moreViewController.show(makeTransportationViewController(), sender: nil)
    }

    private func showInfoViewController(withTitle title: String, for info: Info) {
        services.infoService.loadAttributedText(for: info) { [weak moreViewController] attributedText in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                if let attributedText = attributedText {
                    let textViewController = self.makeTextViewController()
                    textViewController.attributedText = attributedText
                    textViewController.title = title

                    let textNavigationController = UINavigationController(rootViewController: textViewController)
                    moreViewController?.showDetailViewController(textNavigationController, sender: nil)
                } else {
                    moreViewController?.present(ErrorController(), animated: true)
                }
            }
        }
    }

    private func moreViewControllerDidSelectAcknowledgements(_ moreViewController: MoreViewController) {
        DispatchQueue.global().async { [weak self, weak moreViewController] in
            let acknowledgements = self?.services.acknowledgementsService.loadAcknowledgements()

            DispatchQueue.main.async {
                guard let self = self, let moreViewController = moreViewController else { return }

                if let acknowledgements = acknowledgements {
                    self.acknowledgements = acknowledgements

                    let acknowledgementsViewController = self.makeAcknowledgementsViewController()
                    moreViewController.show(acknowledgementsViewController, sender: nil)
                } else {
                    moreViewController.present(ErrorController(), animated: true)
                }
            }
        }
    }
}

#if DEBUG
    extension MoreController: UIPopoverPresentationControllerDelegate, DateViewControllerDelegate {
        private func moreViewControllerDidSelectTime(_ moreViewController: MoreViewController) {
            let date = services.debugService.now
            let dateViewController = makeDateViewController(for: date)
            moreViewController.present(dateViewController, animated: true)
        }

        func dateViewControllerDidChange(_ dateViewController: DateViewController) {
            let date = dateViewController.date
            services.debugService.override(date)
        }

        private func makeDateViewController(for date: Date) -> DateViewController {
            let timeViewController = DateViewController()
            timeViewController.delegate = self
            timeViewController.date = date
            return timeViewController
        }
    }
#endif

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
                    let licenseNavigationController = UINavigationController(rootViewController: licenseViewController)
                    acknowledgementsViewController.showDetailViewController(licenseNavigationController, sender: nil)
                } else {
                    let errorViewController = ErrorController()
                    acknowledgementsViewController.present(errorViewController, animated: true)
                }
            }
        }
    }
}

extension MoreController: TransportationViewControllerDelegate {
    func transportationViewController(_ transportationViewController: TransportationViewController, didSelect item: TransportationViewController.Item) {
        switch item {
        case .appleMaps:
            UIApplication.shared.open(.ulbAppleMaps) { [weak transportationViewController] _ in
                transportationViewController?.deselectSelectedRow(animated: true)
            }
        case .googleMaps:
            UIApplication.shared.open(.ulbGoogleMaps) { [weak transportationViewController] _ in
                transportationViewController?.deselectSelectedRow(animated: true)
            }
        case .bus:
            showInfoViewController(withTitle: item.title, for: .bus)
        case .shuttle:
            showInfoViewController(withTitle: item.title, for: .shuttle)
        case .train:
            showInfoViewController(withTitle: item.title, for: .train)
        case .car:
            showInfoViewController(withTitle: item.title, for: .car)
        case .plane:
            showInfoViewController(withTitle: item.title, for: .plane)
        case .taxi:
            showInfoViewController(withTitle: item.title, for: .taxi)
        }
    }
}

extension MoreController: YearsViewControllerDataSource, YearsViewControllerDelegate {
    func numberOfYears(in _: YearsViewController) -> Int {
        years.count
    }

    func yearsViewController(_: YearsViewController, yearAt index: Int) -> String {
        years[index]
    }

    func yearsViewController(_ yearsViewController: YearsViewController, didSelect year: String) {
        services.yearsService.loadURL(forYear: year) { [weak self, weak yearsViewController] url in
            guard let self = self, let yearsViewController = yearsViewController else { return }

            guard let url = url else {
                return self.presentYearErrorViewController(from: yearsViewController)
            }

            do {
                let persistenceService = try PersistenceService(path: url.path, migrations: .allMigrations)
                self.showYearViewController(forYear: year, with: persistenceService, from: yearsViewController)
            } catch {
                assertionFailure(error.localizedDescription)
                self.presentYearErrorViewController(from: yearsViewController)
            }
        }
    }

    private func presentYearErrorViewController(from yearsViewController: YearsViewController) {
        DispatchQueue.main.async { [weak yearsViewController] in
            yearsViewController?.present(ErrorController(), animated: true)
        }
    }

    private func showYearViewController(forYear year: String, with persistenceService: PersistenceService, from yearsViewController: YearsViewController) {
        DispatchQueue.main.async { [weak self, weak yearsViewController] in
            guard let self = self else { return }

            let yearViewController = self.makeYearViewController(forYear: year, with: persistenceService)
            yearsViewController?.show(yearViewController, sender: nil)
        }
    }
}

extension MoreController: YearControllerDelegate {
    func yearControllerDidError(_: YearController) {
//        popToRootViewController(animated: true)
        present(ErrorController(), animated: true)
    }
}

private extension MoreController {
    func makeMoreViewController() -> MoreViewController {
        let moreViewController = MoreViewController(style: .grouped)
        moreViewController.title = NSLocalizedString("more.title", comment: "")
        moreViewController.delegate = self
        self.moreViewController = moreViewController
        return moreViewController
    }

    func makeTextViewController() -> TextViewController {
        TextViewController()
    }

    func makeYearsViewController() -> YearsViewController {
        let yearsViewController = YearsViewController()
        yearsViewController.title = NSLocalizedString("years.title", comment: "")
        yearsViewController.dataSource = self
        yearsViewController.delegate = self
        return yearsViewController
    }

    private func makeTransportationViewController() -> TransportationViewController {
        let transportationViewController = TransportationViewController(style: .grouped)
        transportationViewController.title = NSLocalizedString("transportation.title", comment: "")
        transportationViewController.delegate = self
        return transportationViewController
    }

    func makeAcknowledgementsViewController() -> AcknowledgementsViewController {
        let acknowledgementsViewController = AcknowledgementsViewController(style: .grouped)
        acknowledgementsViewController.title = NSLocalizedString("acknowledgements.title", comment: "")
        acknowledgementsViewController.dataSource = self
        acknowledgementsViewController.delegate = self
        return acknowledgementsViewController
    }

    func makeLicenseViewController(for acknowledgement: Acknowledgement, withLicense license: String) -> TextViewController {
        let licenseViewController = TextViewController()
        licenseViewController.title = acknowledgement
        licenseViewController.text = license
        return licenseViewController
    }

    func makeYearViewController(forYear year: String, with persistenceService: PersistenceService) -> YearController {
        let yearController = YearController(year: year, persistenceService: persistenceService)
        yearController.delegate = self
        yearController.title = year

        if #available(iOS 11.0, *) {
            yearController.navigationItem.largeTitleDisplayMode = .never
        }

        return yearController
    }
}

private extension URL {
    static var ulbAppleMaps: URL {
        URL(string: "https://maps.apple.com/?address=Avenue%20Franklin%20Roosevelt%2050,%201050%20Brussels,%20Belgium&auid=2450730505287536200&ll=50.812050,4.382236&lsp=9902&q=Universit%C3%A9%20Libre%20de%20Bruxelles&_ext=ChgKBAgEEFcKBAgFEAMKBAgGEBkKBAgKEAESJCkjtQWwbFxJQDFgm0ZDufUQQDkZviUmcHNJQEGgZLl8GBkSQA%3D%3D")!
    }

    static var ulbGoogleMaps: URL {
        URL(string: "https://www.google.com/maps/place/Universit%C3%A9+Libre+de+Bruxelles/@50.8132068,4.3800335,17z/data=!3m1!4b1!4m5!3m4!1s0x47c3c4485d19ce43:0xe8eb9253c07c6691!8m2!3d50.8132068!4d4.3822222")!
    }
}
