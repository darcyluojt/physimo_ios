import Foundation
import Vision
import CoreGraphics
import SwiftUI

final class Vision2DProcessor{

    func detect2dPoses(
        in cgImage: CGImage,
        orientation: CGImagePropertyOrientation? = nil
      ) async throws -> BodyDetectionResult? {
        let request = DetectHumanBodyPoseRequest()
        do {
            let observations: [HumanBodyPoseObservation] =
                try await request.perform(on: cgImage, orientation: orientation)
            guard let first = observations.first else { return nil }

            var result = BodyDetectionResult()
            let joints = first.allJoints()

            for (jointName, joint) in joints {
                let bodyPart = jointName.toBodyPart()
                // Apple Vision uses bottom-left origin, flip Y coordinate for top-left origin
                let flippedY = 1.0 - joint.location.y
                let position2D = SIMD2<Float>(Float(joint.location.x), Float(flippedY))
                let position3D = SIMD3<Float>(Float(joint.location.x), Float(flippedY), 0)

                result.landmarks[bodyPart] = BodyLandmark(position3D: position3D, position2D: position2D)
            }

            return result
        } catch {
            print("Vision 2D", error)
            return nil
        }
    }
}



