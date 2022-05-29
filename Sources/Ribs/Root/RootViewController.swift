import RIBs
import UIKit

class RootViewController: UITabBarController {
  private var agendaViewController: UIViewController? {
    didSet { didChangeViewControllers() }
  }

  private var mapViewController: UIViewController? {
    didSet { didChangeViewControllers() }
  }

  private var moreViewController: UIViewController? {
    didSet { didChangeViewControllers() }
  }

  private var scheduleViewController: UIViewController? {
    didSet { didChangeViewControllers() }
  }

  private func didChangeViewControllers() {
    let viewControllers = [scheduleViewController, agendaViewController, mapViewController, moreViewController]
    self.viewControllers = viewControllers.compactMap { $0 }
  }
}

extension RootViewController: RootViewControllable {
  func addAgenda(_ agendaViewControllable: ViewControllable) {
    agendaViewController = agendaViewControllable.uiviewController
    agendaViewController?.title = L10n.Agenda.title
    agendaViewController?.tabBarItem.accessibilityIdentifier = "agenda"
    agendaViewController?.tabBarItem.image = .fos_systemImage(withName: "calendar")
  }

  func addMap(_ mapViewControllable: ViewControllable) {
    mapViewController = mapViewControllable.uiviewController
    mapViewController?.title = L10n.Map.title
    mapViewController?.tabBarItem.accessibilityIdentifier = "map"
    mapViewController?.tabBarItem.image = .fos_systemImage(withName: "map")
  }

  func addMore(_ mapViewControllable: ViewControllable) {
    moreViewController = mapViewControllable.uiviewController
    moreViewController?.title = L10n.More.title
    moreViewController?.tabBarItem.accessibilityIdentifier = "more"
    moreViewController?.tabBarItem.image = .fos_systemImage(withName: "ellipsis.circle")
  }

  func addSchedule(_ scheduleViewControllable: ViewControllable) {
    scheduleViewController = scheduleViewControllable.uiviewController
    scheduleViewController?.title = L10n.Search.title
    scheduleViewController?.tabBarItem.accessibilityIdentifier = "search"
    scheduleViewController?.tabBarItem.image = .fos_systemImage(withName: "magnifyingglass")
  }

  func removeAgenda() {
    agendaViewController = nil
  }

  func removeMap() {
    mapViewController = nil
  }

  func removeSchedule() {
    scheduleViewController = nil
  }
}
