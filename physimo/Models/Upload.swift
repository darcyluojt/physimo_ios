import Foundation
struct Upload: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let mediaURL: URL
    let mediaType: MediaType
    let timestamp: Date
    var metrics: [Metric]?
}

enum MediaType: String, Codable {
        case photo
        case video
    }
