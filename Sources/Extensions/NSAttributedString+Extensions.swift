import UIKit

extension NSAttributedString {
    convenience init(html data: Data) throws {
        try self.init(data: data, options: .htmlDecodingOptions, documentAttributes: nil)
    }
}

private extension Dictionary where Key == NSAttributedString.DocumentReadingOptionKey, Value == Any {
    static var htmlDecodingOptions: [NSAttributedString.DocumentReadingOptionKey: Any] {
        [
            .characterEncoding: NSNumber(value: String.Encoding.utf8.rawValue),
            .documentType: NSAttributedString.DocumentType.html,
        ]
    }
}
