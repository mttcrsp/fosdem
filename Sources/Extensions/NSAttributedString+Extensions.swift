import UIKit

private extension Dictionary where Key == NSAttributedString.DocumentReadingOptionKey, Value == Any {
    static var htmlDecodingOptions: [NSAttributedString.DocumentReadingOptionKey: Any] {
        [
            .characterEncoding: NSNumber(value: String.Encoding.utf8.rawValue),
            .documentType: NSAttributedString.DocumentType.html,
        ]
    }
}

// HACK: -[NSAttributedString initWithData:options:documentAttributes:]
// will deadlock if invoked from different threads.
@objc extension NSAttributedString {
    class func fromHTML(_ data: Data) throws -> NSAttributedString {
        try onMainThread { try NSAttributedString(data: data, options: .htmlDecodingOptions, documentAttributes: nil) }
    }
}

@objc extension NSMutableAttributedString {
    override class func fromHTML(_ data: Data) throws -> NSMutableAttributedString {
        try onMainThread { try NSMutableAttributedString(data: data, options: .htmlDecodingOptions, documentAttributes: nil) }
    }
}

private func onMainThread<T>(_ work: () throws -> T) rethrows -> T {
    if Thread.isMainThread {
        return try work()
    } else {
        var result: T!
        try DispatchQueue.main.sync {
            result = try work()
        }
        return result
    }
}
