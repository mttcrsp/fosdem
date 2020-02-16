@testable
import Fosdem
import Foundation

final class AcknowledgementsServicePlistMock: AcknowledgementsServicePlist {
    private(set) var path: String?
    private let dictionary: NSDictionary?

    init(dictionary: NSDictionary?) {
        self.dictionary = dictionary
    }

    func dictionary(withContentsOfFile path: String) -> NSDictionary? {
        self.path = path
        return dictionary
    }
}
