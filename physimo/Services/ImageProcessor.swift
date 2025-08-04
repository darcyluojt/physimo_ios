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
    func process(image: UIImage) async throws -> (pose2D: BodyDetectionResult?, pose3D: BodyDetectionResult?, mpPose: MediaPipePoseResult?){

//        1. Define image orientation
        let uii_orientation = image.imageOrientation
        let cgi_orientation = CGImagePropertyOrientation(uii_orientation)
        print("📸 ImageProcessor Debug:")
        print("  UIImage orientation: \(uii_orientation.rawValue) (\(orientationName(uii_orientation)))")
        print("  CGImage orientation: \(cgi_orientation.rawValue)")
        print("  Original UIImage size: \(image.size)")
        print("  UIImage scale: \(image.scale)")
        
        // Log image metadata
        if let cgImage = image.cgImage {
            print("  CGImage size: \(cgImage.width) x \(cgImage.height)")
            print("  CGImage bits per component: \(cgImage.bitsPerComponent)")
            print("  CGImage bits per pixel: \(cgImage.bitsPerPixel)")
            print("  CGImage color space: \(cgImage.colorSpace?.name ?? "unknown" as CFString)")
            print("  CGImage alpha info: \(cgImage.alphaInfo.rawValue)")
        }
        
        // Calculate image file size if possible
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            let fileSizeKB = Double(imageData.count) / 1024.0
            let fileSizeMB = fileSizeKB / 1024.0
            print("  Estimated file size: \(String(format: "%.1f", fileSizeMB)) MB (\(String(format: "%.0f", fileSizeKB)) KB)")
        }
        
        // Calculate pixel count
        let totalPixels = image.size.width * image.size.height
        let megapixels = totalPixels / 1_000_000
        print("  Total pixels: \(String(format: "%.1f", megapixels)) MP (\(Int(totalPixels)) pixels)")
        
//        2. Process image
        guard let cgImage = image.cgImage else {
            throw Error.invalidImage
        }
        
        // Create UIImage from CGImage without orientation to get raw pixel data
        let rawUIImage = UIImage(cgImage: cgImage)
        let mpi_image = try MPImage(uiImage: rawUIImage)
        print("  MPImage created from UIImage(cgImage:) - raw pixel data without orientation")
        

//        3.1 Detect 2D poses using cgImage using Apple tool
        let poses2D = try await detect2DPoses(in: cgImage, orientation: cgi_orientation)
//        3.2 Detect 3D pose using cgImage using Apple tool
        let poses3D = try await detect3DPoses(in: cgImage)
//        3.1 Detect pose landmarks using mpi image using mediapipe
        let mp_result = detectMediaPipe(image: mpi_image)
        
        // Log processing results
        print("📊 Processing Results:")
        print("  Apple 2D pose detected: \(poses2D != nil)")
        print("  Apple 3D pose detected: \(poses3D != nil)")
        print("  MediaPipe pose detected: \(mp_result != nil)")
        
        if let mpResult = mp_result {
            print("  MediaPipe landmarks count: \(mpResult.landmarks2D.count)")
            print("  MediaPipe 3D landmarks count: \(mpResult.landmarks3D.count)")
            
            // Log first few landmark positions for debugging
            if !mpResult.landmarks2D.isEmpty {
                print("  First 3 MP landmarks:")
                for i in 0..<min(3, mpResult.landmarks2D.count) {
                    let landmark = mpResult.landmarks2D[i]
                    print("    [\(i)] x:\(String(format: "%.3f", landmark.x)), y:\(String(format: "%.3f", landmark.y)), z:\(String(format: "%.3f", landmark.z))")
                }
            }
        }
        print("🔚 ImageProcessor Debug End\n")
        
        return (poses2D, poses3D, mp_result)
        
    }
    
    /// Calls the Vision2DProcessor
    private func detect2DPoses(in cgImage: CGImage, orientation: CGImagePropertyOrientation) async throws -> BodyDetectionResult? {
        return try await vision2D.detect2dPoses(in: cgImage, orientation: orientation)
    }
    
    /// Calls the Vision3DProcessor
    private func detect3DPoses(in cgImage: CGImage) async throws -> BodyDetectionResult? {
        return try await vision3D.detect3dPoses(in: cgImage)
    }
    
//    typealias MediaPipePoseResult = (landmarks2D: [NormalizedLandmark], landmarks3D: [Landmark])

    
    private func detectMediaPipe(image: MPImage) -> MediaPipePoseResult? {
        
        let modelPath = Bundle.main.path(forResource: "pose_landmarker_heavy",
                                         ofType: "task")
        guard let landmarker = MediapipeProcessor.stillImageLandmarkerService(
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
    
    private func orientationName(_ orientation: UIImage.Orientation) -> String {
        switch orientation {
        case .up: return "Up"
        case .down: return "Down (180°)"
        case .left: return "Left (90° CCW)"
        case .right: return "Right (90° CW)"
        case .upMirrored: return "Up Mirrored"
        case .downMirrored: return "Down Mirrored"
        case .leftMirrored: return "Left Mirrored"
        case .rightMirrored: return "Right Mirrored"
        @unknown default: return "Unknown"
        }
    }
}

