import Foundation
struct Metric: Identifiable {
    let id: UUID
    let archetype: Archetype
    let source: Source
    var value: Double
    var accuracy: Double?
    var ignored: Bool = false
    var videoTimestamp: Double? = nil
    let phtoTimestamp: Date

    enum Source: String, Codable {
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
