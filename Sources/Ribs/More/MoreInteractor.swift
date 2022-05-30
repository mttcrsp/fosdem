import Foundation
import RIBs

protocol MoreRouting: ViewableRouting {
  func routeToVideos()
  func routeToYears()
  func routeBackFromVideos()
  func routeBackFromYears()
}

protocol MorePresentable: Presentable {
  func deselectSelectedAcknowledgment()
  func deselectSelectedItem()
  func deselectSelectedTransportationItem()

  func hideVideos()
  func hideYears()

  func showError()
  func showAcknowledgements(_ acknowledgements: [Acknowledgement])
  func showInfo(_ info: Info, attributedString: NSAttributedString)
  func showTransportation()
  func showTransportationInfo(_ info: Info, attributedString: NSAttributedString)
  #if DEBUG
  func showDate(_ date: Date)
  #endif
}

final class MoreInteractor: PresentableInteractor<MorePresentable> {
  weak var router: MoreRouting?

  private var acknowledgements: [Acknowledgement] = []

  private let dependency: MoreDependency

  init(presenter: MorePresentable, dependency: MoreDependency) {
    self.dependency = dependency
    super.init(presenter: presenter)
  }
}

extension MoreInteractor: MoreInteractable {
  func videosDidDismiss() {
    router?.routeBackFromVideos()
  }

  func videosDidError(_: Error) {
    presenter.hideVideos()
    presenter.showError()
  }

  func yearsDidError(_: Error) {
    presenter.hideYears()
    presenter.showError()
  }
}

extension MoreInteractor: MorePresentableListener {
  func select(_ item: MoreItem) {
    switch item {
    case .acknowledgements:
      do {
        presenter.showAcknowledgements(
          try dependency.acknowledgementsService.loadAcknowledgements()
        )
      } catch {
        presenter.showError()
      }
    case .code:
      if let url = URL.fosdemGithub {
        dependency.openService.open(url) { [weak self] _ in
          self?.presenter.deselectSelectedItem()
        }
      }
    case .history, .legal, .devrooms:
      if let info = item.info {
        dependency.infoService.loadAttributedText(for: info) { [weak self] result in
          DispatchQueue.main.async {
            switch result {
            case .failure:
              self?.presenter.showError()
            case let .success(attributedString):
              self?.presenter.showInfo(info, attributedString: attributedString)
            }
          }
        }
      }
    case .transportation:
      presenter.showTransportation()
    case .video:
      router?.routeToVideos()
    case .years:
      router?.routeToYears()
    #if DEBUG
    case .time:
      presenter.showDate(dependency.timeService.now)
    #endif
    }
  }

  func select(_ item: TransportationItem) {
    switch item {
    case .appleMaps:
      dependency.openService.open(.ulbAppleMaps) { [weak self] _ in
        self?.presenter.deselectSelectedTransportationItem()
      }
    case .googleMaps:
      dependency.openService.open(.ulbGoogleMaps) { [weak self] _ in
        self?.presenter.deselectSelectedTransportationItem()
      }
    case .bus, .car, .taxi, .plane, .train, .shuttle:
      if let info = item.info {
        dependency.infoService.loadAttributedText(for: info) { [weak self] result in
          DispatchQueue.main.async {
            switch result {
            case .failure:
              self?.presenter.showError()
            case let .success(attributedString):
              self?.presenter.showTransportationInfo(info, attributedString: attributedString)
            }
          }
        }
      }
    }
  }

  func select(_ acknowledgement: Acknowledgement) {
    open(acknowledgement.url) { [weak self] in
      self?.presenter.deselectSelectedAcknowledgment()
    }
  }

  #if DEBUG
  func select(_ date: Date) {
    dependency.timeService.now = date
  }
  #endif

  func deselectVideos() {
    router?.routeBackFromVideos()
  }

  func deselectYears() {
    router?.routeBackFromYears()
  }

  private func open(_ url: URL, completion: @escaping () -> Void) {
    dependency.openService.open(url) { _ in
      completion()
    }
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
