import Foundation
struct Metric: Identifiable, Decodable {
    let id: UUID
    let uploadId: UUID?
    let archetype: Archetype
    let source: Source
    var value: Double
    var accuracy: Double?
    var ignored: Bool = false
    var videoTimestamp: Double? = nil
    
    enum CodingKeys: String, CodingKey {
        case id
        case uploadId = "upload_id"  // ← you must include this
        case accuracy
        case archetype
        case value
        case source
       }
    
    enum Source: String, Decodable {
        case HumanBodyPose3DObservation
        case HumanBodyPoseObservation
        case MediaPipePoseWorldLandmarks
        case MediaPipePoseLandmarks
        var displayName: String {
                switch self {
                case .HumanBodyPose3DObservation: return "Apple 3D Pose"
                case .HumanBodyPoseObservation: return "Apple 2D Pose"
                case .MediaPipePoseWorldLandmarks: return "MediaPipe 3D"
                case .MediaPipePoseLandmarks: return "MediaPipe 2D"
                }
            }
    }
}
