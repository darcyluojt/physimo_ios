import Foundation
import Vision
import CoreGraphics

final class Vision3DProcessor{
    func detect3dPoses(in cgImage: CGImage) async throws -> BodyDetectionResult? {
        let request = DetectHumanBodyPose3DRequest()
        let handler = ImageRequestHandler(cgImage)
        do {
            let observations = try await handler.perform(request)
            if let observation = observations.first {
                var result = BodyDetectionResult()
                let joints = observation.allJoints()

                for (jointName, joint) in joints {
                    let bodyPart = jointName.toBodyPart()
                    // Extract 3D position from the 4th column of the transformation matrix
                    let transform = joint.position
                    let position3D = SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)

                    result.landmarks[bodyPart] = BodyLandmark(position3D: position3D)
                }

                return result
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


