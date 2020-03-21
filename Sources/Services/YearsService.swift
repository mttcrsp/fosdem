import Foundation

protocol YearsServiceBundle {
    func urls(forResourcesWithExtension ext: String?, subdirectory subpath: String?) -> [URL]?
}

extension Bundle: YearsServiceBundle {}

final class YearsService {
    let bundle: YearsServiceBundle

    init(bundle: YearsServiceBundle = Bundle.main) {
        self.bundle = bundle
    }

    func loadYears(_ completion: @escaping ([String]) -> Void) {
        DispatchQueue.global().async { [weak self] in
            if let self = self {
                let urls = self.bundle.urls(forResourcesWithExtension: "sqlite", subdirectory: nil) ?? []
                var years = urls.map { url in url.lastPathComponent.replacingOccurrences(of: ".sqlite", with: "") }
                years.sort(by: >)
                completion(years)
            }
        }
    }
}
