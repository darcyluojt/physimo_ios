import Foundation
import Vision
import CoreGraphics
import SwiftUI

struct DetectionResult2D {
    let observation: HumanBodyPoseObservation
    
    func joints(for group: HumanBodyPoseObservation.JointsGroupName) -> [HumanBodyPoseObservation.JointName: Joint] {
        observation.allJoints(in: group)
    }
    
    func allJoints() -> [HumanBodyPoseObservation.JointName: Joint] {
        observation.allJoints()
    }
}
    
final class Vision2DProcessor{
    func detect2dPoses(
        in cgImage: CGImage,
        orientation: CGImagePropertyOrientation? = nil
      ) async throws -> DetectionResult2D? {
        let request = DetectHumanBodyPoseRequest()
        do {
            let observations: [HumanBodyPoseObservation] =
                try await request.perform(on: cgImage, orientation: orientation)
            guard let first = observations.first else { return nil }
            print("Vision 2D:", first.allJoints())
            return DetectionResult2D(observation: first)
        } catch {
            print("Vision 2D", error)
            return nil
        }
        
    }
}



