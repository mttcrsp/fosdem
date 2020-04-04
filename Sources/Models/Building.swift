import MapKit

struct Blueprint: Decodable {
    let title: String
    let imageName: String
}

class Building: NSObject, Decodable, MKAnnotation {
    let glyph: String
    let title: String?
    let polygon: MKPolygon
    let blueprints: [Blueprint]
    let coordinate: CLLocationCoordinate2D

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        blueprints = try container.decode([Blueprint].self, forKey: .blueprints)

        let title = try container.decode(String.self, forKey: .title)
        self.title = title

        let glyph = try container.decodeIfPresent(String.self, forKey: .glyph)
        self.glyph = glyph ?? title

        let coordinate = try container.decode(Coordinate.self, forKey: .coordinate)
        self.coordinate = CLLocationCoordinate2D(coordinate: coordinate)

        let coordinates = try container.decode([Coordinate].self, forKey: .polygon)
        var coordinatesCL = coordinates.map(CLLocationCoordinate2D.init)
        polygon = MKPolygon(coordinates: &coordinatesCL, count: coordinatesCL.count)
    }

    private enum CodingKeys: String, CodingKey {
        case glyph, title, polygon, blueprints, coordinate
    }
}

private struct Coordinate: Decodable {
    let latitude, longitude: Double
}

private extension CLLocationCoordinate2D {
    init(coordinate: Coordinate) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
