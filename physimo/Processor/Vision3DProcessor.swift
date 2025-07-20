import Foundation
import Vision
import CoreGraphics

struct DetectionResult {
    let observation: HumanBodyPose3DObservation
    
    func joints(for group: HumanBodyPose3DObservation.JointsGroupName) -> [HumanBodyPose3DObservation.JointName: Joint3D] {
        observation.allJoints(in: group)
    }
    
    func allJoints() -> [HumanBodyPose3DObservation.JointName: Joint3D] {
        observation.allJoints()
    }
}
    
final class Vision3DProcessor{
    func detect3dPoses(in cgImage: CGImage) async throws -> DetectionResult? {
        let request = DetectHumanBodyPose3DRequest()
        let handler = ImageRequestHandler(cgImage)
        do {
            let observations = try await handler.perform(request)
            if let observation = observations.first {
                print("3D observation", observation)
                return DetectionResult(observation: observation)
            } else {
                print("No pose detected.")
                return nil
            }
        } catch {
            print("Pose detection error \(error)")
            return nil
        }
    }
}


