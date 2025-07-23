import Foundation
import UIKit

struct StoredUpload: Codable, Identifiable {
    let id: UUID
    let imageData: Data
    let metrics: [Metric]

    init(id: UUID, image: UIImage, metrics: [Metric]) {
        self.id = id
        self.imageData = image.pngData() ?? Data()
        self.metrics = metrics
    }

    // This computed property should be ignored by the Codable system
    var image: UIImage? {
        return UIImage(data: imageData)
    }

    // Explicit CodingKeys if needed (optional here because all stored properties are Codable)
    private enum CodingKeys: String, CodingKey {
        case id, imageData, metrics
    }
}

class UploadStore {
  static let shared = UploadStore()
  private let fileManager = FileManager.default
  private lazy var documentsURL: URL = {
    let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
    let url = urls[0]
    print("[UploadStore] Documents directory: \(url.path)") // Debug: show path
    return url
  }()

  private init() {}

  func save(_ upload: StoredUpload) {
        let filename = "upload_\(upload.id).json"
        let url = documentsURL.appendingPathComponent(filename)
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(upload)
            try data.write(to: url, options: .atomic)
            print("[UploadStore] Saved upload to \(url.path)") // Debug: confirm save
        } catch {
            print("[UploadStore][Error] Failed to save upload: \(error)")
        }
    }

    /// Fetch all saved StoredUpload objects from disk.
    /// - Returns: Array of StoredUpload
  func fetchAll() -> [StoredUpload] {
      print("[UploadStore] Fetching all uploads...") // Debug: start fetch
      do {
          let files = try fileManager.contentsOfDirectory(at: documentsURL,
                                                          includingPropertiesForKeys: nil,
                                                          options: [])
          var uploads: [StoredUpload] = []
          for url in files {
              guard url.pathExtension == "json" else { continue }
              do {
                  let data = try Data(contentsOf: url)
                  let upload = try JSONDecoder().decode(StoredUpload.self, from: data)
                  uploads.append(upload)
              } catch {
                  print("[UploadStore][Error] Failed to load upload at \(url.path): \(error)")
              }
          }
          print("[UploadStore] Fetched \(uploads.count) uploads") // Debug: count
          return uploads
      } catch {
          print("[UploadStore][Error] Failed to list documents: \(error)")
          return []
      }
  }

    /// Delete a specific StoredUpload and its file.
    /// - Parameter upload: The StoredUpload to delete.
  func delete(_ upload: StoredUpload) {
      let filename = "upload_\(upload.id).json"
      let url = documentsURL.appendingPathComponent(filename)
      do {
          try fileManager.removeItem(at: url)
          print("[UploadStore] Deleted upload file at \(url.path)") // Debug: confirm deletion
      } catch {
          print("[UploadStore][Error] Failed to delete upload: \(error)")
      }
  }
}
