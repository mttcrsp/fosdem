import CoreLocation
import UIKit

protocol MapControlsViewDelegate: AnyObject {
    func controlsViewDidTapReset(_ controlsView: MapControlsView)
    func controlsViewDidTapLocation(_ controlsView: MapControlsView)
}

final class MapControlsView: UIView {
    weak var delegate: MapControlsViewDelegate?

    private let locationButton = UIButton()

    override init(frame: CGRect) {
        super.init(frame: frame)

        let resetImage = UIImage.fos_systemImage(withName: "arrow.counterclockwise")
        let resetAction = #selector(didTapReset)
        let resetButton = UIButton()
        resetButton.contentEdgeInsets = .zero
        resetButton.imageView?.contentMode = .center
        resetButton.setImage(resetImage, for: .normal)
        resetButton.addTarget(self, action: resetAction, for: .touchUpInside)

        let locationImage = CLAuthorizationStatus.notDetermined.image
        let locationAction = #selector(didTapLocation)
        locationButton.contentEdgeInsets = .zero
        locationButton.imageView?.contentMode = .center
        locationButton.setImage(locationImage, for: .normal)
        locationButton.addTarget(self, action: locationAction, for: .touchUpInside)

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

        NSLayoutConstraint.activate([
            resetButton.widthAnchor.constraint(equalToConstant: buttonSize),
            resetButton.widthAnchor.constraint(equalTo: resetButton.heightAnchor),
            locationButton.widthAnchor.constraint(equalToConstant: buttonSize),
            locationButton.widthAnchor.constraint(equalTo: locationButton.heightAnchor),
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

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setAuthorizationStatus(_ status: CLAuthorizationStatus) {
        locationButton.setImage(status.image, for: .normal)
    }

    @objc private func didTapReset() {
        delegate?.controlsViewDidTapReset(self)
    }

    @objc private func didTapLocation() {
        delegate?.controlsViewDidTapLocation(self)
    }
}

extension CLAuthorizationStatus {
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
