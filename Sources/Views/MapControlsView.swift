import CoreLocation
import UIKit

protocol MapControlsViewDelegate: AnyObject {
  func controlsViewDidTapReset(_ controlsView: MapControlsView)
  func controlsViewDidTapLocation(_ controlsView: MapControlsView)
}

final class MapControlsView: UIView {
  weak var delegate: MapControlsViewDelegate?

  var showsTitles = false {
    didSet { didChangeTitleVisibility() }
  }

  var authorizationStatus: CLAuthorizationStatus = .notDetermined {
    didSet { didChangeAuthorizationStatus() }
  }

  private var noTitlesConstraints: [NSLayoutConstraint] = []

  private let locationButton = UIButton()
  private let resetButton = UIButton()

  override init(frame: CGRect) {
    super.init(frame: frame)

    let resetImage = UIImage.fos_systemImage(withName: "arrow.counterclockwise")
    let resetAction = #selector(didTapReset)
    resetButton.setImage(resetImage, for: .normal)
    resetButton.addTarget(self, action: resetAction, for: .touchUpInside)
    resetButton.accessibilityLabel = NSLocalizedString("map.reset", comment: "")
    resetButton.accessibilityIdentifier = "reset"

    let locationImage = CLAuthorizationStatus.notDetermined.image
    let locationAction = #selector(didTapLocation)
    locationButton.setImage(locationImage, for: .normal)
    locationButton.addTarget(self, action: locationAction, for: .touchUpInside)
    locationButton.accessibilityLabel = CLAuthorizationStatus.notDetermined.title

    for button in buttons {
      button.imageView?.contentMode = .center
      button.setTitleColor(.fos_label, for: .normal)
    }

    let separatorView = UIView()
    separatorView.backgroundColor = .fos_separator

    let backgroundView = UIView()
    backgroundView.backgroundColor = .fos_tertiarySystemBackground
    backgroundView.translatesAutoresizingMaskIntoConstraints = false
    backgroundView.layer.cornerRadius = 8
    backgroundView.layer.shadowRadius = 8
    backgroundView.layer.shadowOpacity = 0.2
    backgroundView.layer.shadowOffset = .zero
    backgroundView.layer.masksToBounds = true
    backgroundView.layer.shadowColor = UIColor.black.cgColor
    addSubview(backgroundView)

    let stackView = UIStackView(arrangedSubviews: [locationButton, separatorView, resetButton])
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    addSubview(stackView)

    let buttonSize: CGFloat = 44
    noTitlesConstraints = [
      resetButton.widthAnchor.constraint(equalToConstant: buttonSize),
      resetButton.widthAnchor.constraint(equalTo: resetButton.heightAnchor),
      locationButton.widthAnchor.constraint(equalToConstant: buttonSize),
      locationButton.widthAnchor.constraint(equalTo: locationButton.heightAnchor),
    ]

    NSLayoutConstraint.activate(noTitlesConstraints + [
      separatorView.heightAnchor.constraint(equalToConstant: 1 / traitCollection.displayScale),

      backgroundView.topAnchor.constraint(equalTo: topAnchor),
      backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
      backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
      backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),

      stackView.topAnchor.constraint(equalTo: topAnchor),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private var buttons: [UIButton] {
    [resetButton, locationButton]
  }

  private var resetTitle: String? {
    showsTitles ? NSLocalizedString("map.reset", comment: "") : nil
  }

  private var locationTitle: String? {
    showsTitles ? authorizationStatus.title : nil
  }

  @objc private func didTapReset() {
    delegate?.controlsViewDidTapReset(self)
  }

  @objc private func didTapLocation() {
    delegate?.controlsViewDidTapLocation(self)
  }

  private func didChangeTitleVisibility() {
    resetButton.setTitle(resetTitle, for: .normal)
    locationButton.setTitle(locationTitle, for: .normal)

    for button in buttons {
      let inset: CGFloat = showsTitles ? 8 : 0
      button.imageEdgeInsets.left = -inset
      button.imageEdgeInsets.right = inset
      button.contentEdgeInsets = showsTitles ? UIEdgeInsets(top: 12, left: 16 + inset, bottom: 12, right: 16) : .zero
    }

    if showsTitles {
      NSLayoutConstraint.deactivate(noTitlesConstraints)
    } else {
      NSLayoutConstraint.activate(noTitlesConstraints)
    }
  }

  private func didChangeAuthorizationStatus() {
    locationButton.setTitle(locationTitle, for: .normal)
    locationButton.setImage(authorizationStatus.image, for: .normal)
    locationButton.accessibilityLabel = authorizationStatus.title
    locationButton.accessibilityIdentifier = authorizationStatus.identifier
  }
}

extension CLAuthorizationStatus {
  var title: String {
    switch self {
    case .notDetermined:
      return NSLocalizedString("map.location", comment: "")
    case .authorizedWhenInUse, .authorizedAlways:
      return NSLocalizedString("map.location.disable", comment: "")
    case .denied, .restricted:
      return NSLocalizedString("map.location.enable", comment: "")
    @unknown default:
      return NSLocalizedString("map.location", comment: "")
    }
  }

  var identifier: String {
    switch self {
    case .notDetermined:
      return "location"
    case .authorizedWhenInUse, .authorizedAlways:
      return "location_available"
    case .denied, .restricted:
      return "location_unavailable"
        @unknown default:
      return "location_unavailable"
    }
  }

  var image: UIImage? {
    switch self {
    case .notDetermined:
      return UIImage.fos_systemImage(withName: "location")
    case .authorizedWhenInUse, .authorizedAlways:
      return UIImage.fos_systemImage(withName: "location.fill")
    case .denied, .restricted:
      return UIImage.fos_systemImage(withName: "location.slash")
        @unknown default:
      return UIImage.fos_systemImage(withName: "location.slash")
    }
  }
}
