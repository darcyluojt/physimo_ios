import UIKit
@preconcurrency import Vision
@preconcurrency import VisionKit

final class ImageProcessor {
    static func process(image: UIImage) async -> DetectionResult? {
        guard let cgImage = image.cgImage else { return nil }
        
        let request = DetectHumanBodyPose3DRequest()
        
        let handler = ImageRequestHandler(cgImage)
        do {
            let observations = try await handler.perform(request)
            if let observation = observations.first {
                print("[PoseObs] \(observation)")
                return DetectionResult(observation: observation)
            } else {
                print("No pose detected.")
                return nil
            }
        } catch {
            print("Post detection failed: \(error)")
            return nil
        }
    }
}

// DEFINE DETECTION RESULT
struct DetectionResult {
    let observation: HumanBodyPose3DObservation

    func joints(for group: HumanBodyPose3DObservation.JointsGroupName) -> [HumanBodyPose3DObservation.JointName: Joint3D] {
            observation.allJoints(in: group)
        }
    
    func allJoints() -> [HumanBodyPose3DObservation.JointName: Joint3D] {
        observation.allJoints()
    }
}
















//import Foundation
////import CoreVideo
////import CoreImage
////import CoreGraphics
//import UIKit
//@preconcurrency import Vision
//
//// MARK: - Domain State --------------------------------------------------------
//
//
//public struct DetectionState: Sendable {
//    public var recognisedPoints2D: [VNHumanBodyPoseObservation.JointName : VNRecognizedPoint]=[:]
//    public var recognisedPoints3D: [VNHumanBodyPose3DObservation.JointName : VNRecognizedPoint3D] = [:]
//    public init(
//        recognisedPoints2D: [VNHumanBodyPoseObservation.JointName : VNRecognizedPoint]=[:],
//        recognisedPoints3D: [VNHumanBodyPose3DObservation.JointName : VNRecognizedPoint3D] = [:]
//    ) {
//        self.recognisedPoints3D = recognisedPoints3D
//        self.recognisedPoints2D = recognisedPoints2D
//    }
//    public func draw(on image: CIImage) -> CIImage {
//        guard !recognisedPoints2D.isEmpty else { return image }
//        
//        let context = CIContext()
//        let cgImage = context.createCGImage(image, from: image.extent)!
//        let size = image.extent.size
//        
//        // Create UIGraphics context to draw on image
//        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
//        let graphicsContext = UIGraphicsGetCurrentContext()!
//        
//        // Draw base image
//        UIImage(cgImage: cgImage).draw(at: .zero)
//        
//        // Configure drawing
//        graphicsContext.setFillColor(UIColor.red.cgColor)
//        let radius: CGFloat = 5.0
//        
//        // Draw each recognised point
//        for (_, point) in recognisedPoints2D {
//            if point.confidence > 0.1 {
//                let x = point.location.x * size.width
//                let y = (1 - point.location.y) * size.height // Flip y-axis
//                let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
//                graphicsContext.fillEllipse(in: rect)
//            }
//        }
//        
//        // Get the new image and convert back to CIImage
//        let drawnImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        
//        return CIImage(image: drawnImage!)!
//    }
//}
//
//// MARK: - Detector ------------------------------------------------------------
//
//public protocol Detector {
//    func detect(
//        in buffer: CVPixelBuffer,
//        using handler: @escaping (DetectionState?) async -> Void
//    )
//}
//
//public final class DummyDetector: Detector {
//    public init() {}
//
//    public func detect(
//        in buffer: CVPixelBuffer,
//        using handler: @escaping (DetectionState?) async -> Void
//    ) {
//        Task {
//            let requestHandler = VNImageRequestHandler(cvPixelBuffer: buffer)
//            let request2D = VNDetectHumanBodyPoseRequest()
//            let request3D = VNDetectHumanBodyPose3DRequest()
//
//            do {
//                try requestHandler.perform([request2D, request3D])
//                
//                guard let result2D = request2D.results?.first as? VNHumanBodyPoseObservation,
//                      let result3D = request3D.results?.first as? VNHumanBodyPose3DObservation else {
//                    await handler(nil)
//                    return
//                }
//
//                let recognisedPoints2D = try result2D.recognizedPoints(.all)
//                let recognisedPoints3D = try result3D.recognizedPoints(.all)
//
//                let state = DetectionState(
//                    recognisedPoints2D: recognisedPoints2D,
//                    recognisedPoints3D: recognisedPoints3D
//                )
//                await handler(state)
//
//            } catch {
//                print("Pose detection failed: \(error)")
//                await handler(nil)
//            }
//        }
//    }
//}
//
//public func runHumanBodyPose3DrequestOnImage (asset: PHAsset?) {
//    if let asset = asset {
//        let request = VNDetectHumanBodyPose3DRequest()
//        self.getAssetFileURL(asset: asset) { (url) in
//            guard let originalFileURL = url else {
//                return
//        }
//            self.fileURL = originalFileURL
//            let reqeustHandler = VNImageRequestHandler(url: originalFileURL)
//            do {
//                try requestHandler.perform([request])
//                if let returnedObservation = request.results?.first {
//                    self.humanObservation = returnedObservation
//                }
//            } catch {
//                print("Failed to perform request: \(error)")
//            }
//            
//        }
//    }
//}
//
//// MARK: - Video Stream Processor ---------------------------------------------
//
//public actor VideoStreamProcessor {
//    private let detector : Detector
//    private var detectionState: DetectionState?
//    private var detectionTask: Task<Void, Never>? = nil
//
//    public init(detector: Detector = DummyDetector()) {
//        self.detector = detector
//    }
//    
//    public func onBuffer(_ buffer: CVPixelBuffer) {
//        guard detectionTask == nil else { return }   // Skip if busy
//
//        detectionTask = Task.detached(priority: .userInitiated) { [weak self] in
//            guard let self else { return }
//            await detector.detect(in: buffer, using: { [weak self] state in
//                    await self?.completeDetection(state)
//            })
//        }
//    }
//    
//    private func completeDetection(_ state: DetectionState?) {
//        detectionState = state
//        detectionTask = nil
//    }
//    
//    public func overlayDetection(on image: CIImage) -> CIImage {
//        return detectionState?.draw(on: image) ?? image
//    }
//}
