import Foundation
public struct Upload: Identifiable, Codable {
    public let id: UUID
    public let imageData: Data         // Persist images as Data in store
    public let timestamp: Date
    public let mediaType: MediaType
    public var metrics: [Metric]
    

    // Computed property for UIImage convenience
    public var image: UIImage? {
        UIImage(data: imageData)
    }

    public init(uploadId: UUID,
                image: UIImage,
                metrics: [Metric],
                timestamp: Date = Date()) {
        self.id = uploadId
        self.timestamp = timestamp
        self.metrics = metrics
        self.imageData = image.jpegData(compressionQuality: 0.8) ?? Data()
    }
}
enum MediaType: String, Codable {
        case photo
        case video
    }
