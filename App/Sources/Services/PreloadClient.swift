import Foundation

struct PreloadClient {
  var databasePath: () throws -> String
  var removeDatabase: () throws -> Void
  var preloadDatabaseIfNeeded: () throws -> Void
}

extension PreloadClient {
  enum Error: CustomNSError {
    case resourceNotFound
  }

  init(bundle: PreloadClientBundle = Bundle.main, fileManager: PreloadClientFile = FileManager.default) {
    let fileName = "db", fileExtension = "sqlite"

    func oldPath() throws -> String {
      if let oldPath = bundle.path(forResource: fileName, ofType: fileExtension) {
        oldPath
      } else {
        throw Error.resourceNotFound
      }
    }

    func newPath() throws -> String {
      let applicationSupportURL = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      let applicationDatabaseURL = applicationSupportURL.appendingPathComponent(fileName).appendingPathExtension(fileExtension)
      return applicationDatabaseURL.path
    }

    databasePath = newPath

    removeDatabase = {
      try fileManager.removeItem(atPath: try newPath())
    }

    preloadDatabaseIfNeeded = {
      let oldPath = try oldPath()
      let newPath = try newPath()
      if !fileManager.fileExists(atPath: newPath) {
        try fileManager.copyItem(atPath: oldPath, toPath: newPath)
      }
    }
  }
}

/// @mockable
protocol PreloadClientFile {
  func fileExists(atPath path: String) -> Bool
  func copyItem(atPath srcPath: String, toPath dstPath: String) throws
  func url(for directory: FileManager.SearchPathDirectory, in domain: FileManager.SearchPathDomainMask, appropriateFor url: URL?, create shouldCreate: Bool) throws -> URL
  func removeItem(atPath path: String) throws
}

extension FileManager: PreloadClientFile {}

/// @mockable
protocol PreloadClientBundle {
  func path(forResource name: String?, ofType ext: String?) -> String?
}

extension Bundle: PreloadClientBundle {}
