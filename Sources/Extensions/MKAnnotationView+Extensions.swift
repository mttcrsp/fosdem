import MapKit

extension MKAnnotationView {
    static var reuseIdentifier: String {
        .init(describing: self)
    }
}
