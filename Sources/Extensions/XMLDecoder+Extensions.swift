import Foundation
import XMLCoder

extension XMLDecoder {
    static let `default`: XMLDecoder = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let decoder = XMLDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }()
}
