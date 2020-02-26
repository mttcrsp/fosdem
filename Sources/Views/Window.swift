import UIKit

final class Window: UIWindow {
    func configure() {
        tintColor = .fos_label
        backgroundColor = .fos_systemBackground
    }

    func configureAppearanceProxies() {
        let navigationBar = UINavigationBar.appearance()
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = false

        let tabBar = UITabBar.appearance()
        tabBar.shadowImage = UIImage()
        tabBar.isTranslucent = false

        let tableView = UITableView.appearance()
        tableView.backgroundColor = .fos_systemBackground
    }
}
