import Foundation

protocol YearsServiceBundle {
    func url(forResource name: String?, withExtension ext: String?) -> URL?
    func urls(forResourcesWithExtension ext: String?, subdirectory subpath: String?) -> [URL]?
}

extension Bundle: YearsServiceBundle {}

final class YearsService {
    private let queue: DispatchQueue
    private let bundle: YearsServiceBundle

    init(bundle: YearsServiceBundle = Bundle.main, queue: DispatchQueue = .global()) {
        self.queue = queue
        self.bundle = bundle
    }

    func loadYears(_ completion: @escaping ([String]) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }

            let urls = self.bundle.urls(forResourcesWithExtension: .databaseExtension, subdirectory: nil) ?? []

            var years = urls.map { url -> String in
                let fileName = url.lastPathComponent
                let fileExtension = String.databaseExtension
                return fileName.replacingOccurrences(of: ".\(fileExtension)", with: "")
            }

            years.sort(by: >)
            completion(years)
        }
    }

    func loadURL(forYear year: String, completion: @escaping (URL?) -> Void) {
        queue.async { [weak self] in
            if let self = self {
                completion(self.bundle.url(forResource: year, withExtension: .databaseExtension))
            }
        }
    }
}

private extension String {
    static var databaseExtension: String {
        "year"
    }
}
