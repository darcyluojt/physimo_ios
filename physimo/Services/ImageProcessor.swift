import UIKit
@preconcurrency import Vision
@preconcurrency import VisionKit
import SwiftUI
import ImageIO
import MediaPipeTasksVision


enum Error: Swift.Error {
  case invalidImage
}

class ImageProcessor {
    private let vision2D = Vision2DProcessor()
    private let vision3D = Vision3DProcessor()
    func process(image: UIImage) async throws -> (pose2D: DetectionResult2D?, pose3D: DetectionResult?, mpPose: MediaPipePoseResult?){

//        1. Define image orientation
        let uii_orientation = image.imageOrientation
        let cgi_orientation = CGImagePropertyOrientation(uii_orientation)
        print("orientation",cgi_orientation)
//        2. Process image
        guard let cgImage = image.cgImage else {
            throw Error.invalidImage
        }
        let mpi_image = try MPImage(uiImage: image, orientation: uii_orientation)
        

//        3.1 Detect 2D poses using cgImage using Apple tool
        let poses2D = try await detect2DPoses(in: cgImage, orientation: cgi_orientation)
//        3.2 Detect 3D pose using cgImage using Apple tool
        let poses3D = try await detect3DPoses(in: cgImage)
//        3.1 Detect pose landmarks using mpi image using mediapipe
        let mp_result = detectMediaPipe(image: mpi_image)
        
        return (poses2D, poses3D, mp_result)
        
    }
    
    /// Calls the Vision2DProcessor
    private func detect2DPoses(in cgImage: CGImage, orientation: CGImagePropertyOrientation) async throws -> DetectionResult2D? {
        return try await vision2D.detect2dPoses(in: cgImage, orientation: orientation)
    }
    
    /// Calls the Vision3DProcessor
    private func detect3DPoses(in cgImage: CGImage) async throws -> DetectionResult? {
        return try await vision3D.detect3dPoses(in: cgImage)
    }
    
//    typealias MediaPipePoseResult = (landmarks2D: [NormalizedLandmark], landmarks3D: [Landmark])

    
    private func detectMediaPipe(image: MPImage) -> MediaPipePoseResult? {
        
        let modelPath = Bundle.main.path(forResource: "pose_landmarker_heavy",
                                         ofType: "task")
        guard let landmarker = PoseLandmarkerService.stillImageLandmarkerService(
            modelPath: modelPath,
            numPoses: 1,
            minPoseDetectionConfidence: 0.5,
            minPosePresenceConfidence: 0.5,
            minTrackingConfidence: 0.5
        ) else {
            print("⚠️ MediaPipe initialization failed")
            return nil
        }
        guard let result = landmarker.detect(image: image) else {
//              let poselandmark2D = result.poseLandmarkerResults.first?.landmarks.first,
//              let poselandmark3D = result.poseLandmarkerResults.first?.worldLandmarks.first else {
            print("⚠️ MediaPipe detection failed")
            return nil
              }

        return result
        
        
        //        /// Calls the MediaPipeProcessor
        //        private func detectMediaPipe(in image: UIImage) async throws -> [MediaPipePose] {
        //            return try await mediaPipe.detectLandmarks(in: image)
        //        }
        //    }
        
        /// Helper for zipping three arrays
        func zip3<A, B, C>(_ a: [A], _ b: [B], _ c: [C]) -> [(A, B, C)] {
            let count = min(a.count, b.count, c.count)
            return (0..<count).map { (a[$0], b[$0], c[$0]) }
        }
    }
}

