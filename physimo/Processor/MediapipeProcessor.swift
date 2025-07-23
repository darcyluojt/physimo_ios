import UIKit
import MediaPipeTasksVision
import AVFoundation

class PoseLandmarkerService: NSObject {
    var poseLandmarker: PoseLandmarker?
    private(set) var runningMode = RunningMode.image
    private var numPoses: Int
    private var minPoseDetectionConfidence: Float
    private var minPosePresenceConfidence: Float
    private var minTrackingConfidence: Float
    private var modelPath: String
    // MARK: - Custom Initializer
    private init?(modelPath: String?,
                  runningMode:RunningMode,
                  numPoses: Int,
                  minPoseDetectionConfidence: Float,
                  minPosePresenceConfidence: Float,
                  minTrackingConfidence: Float) {
        guard let modelPath = modelPath else { return nil }
        self.modelPath = modelPath
        self.runningMode = runningMode
        self.numPoses = numPoses
        self.minPoseDetectionConfidence = minPoseDetectionConfidence
        self.minPosePresenceConfidence = minPosePresenceConfidence
        self.minTrackingConfidence = minTrackingConfidence
        super.init()
        
        createPoseLandmarker()
    }
    
    private func createPoseLandmarker() {
        let poseLandmarkerOptions = PoseLandmarkerOptions()
        poseLandmarkerOptions.runningMode = runningMode
        poseLandmarkerOptions.numPoses = numPoses
        poseLandmarkerOptions.minPoseDetectionConfidence = minPoseDetectionConfidence
        poseLandmarkerOptions.minPosePresenceConfidence = minPosePresenceConfidence
        poseLandmarkerOptions.minTrackingConfidence = minTrackingConfidence
        poseLandmarkerOptions.baseOptions.modelAssetPath = modelPath
        do {
            poseLandmarker = try PoseLandmarker(options: poseLandmarkerOptions)
        }
        catch {
            print(error)
        }
    }
    
    static func stillImageLandmarkerService(
        modelPath: String?,
        numPoses: Int,
        minPoseDetectionConfidence: Float,
        minPosePresenceConfidence: Float,
        minTrackingConfidence: Float) -> PoseLandmarkerService? {
            let poseLandmarkerService = PoseLandmarkerService(
                modelPath: modelPath,
                runningMode: .image,
                numPoses: numPoses,
                minPoseDetectionConfidence: minPoseDetectionConfidence,
                minPosePresenceConfidence: minPosePresenceConfidence,
                minTrackingConfidence: minTrackingConfidence)
            
            return poseLandmarkerService
        }
    
    func detect(image: MPImage) -> MediaPipePoseResult? {
        do {
            let startDate = Date()
            guard let result = try poseLandmarker?.detect(image: image) else {
                return nil
            }
            let inferenceTime = Date().timeIntervalSince(startDate) * 1000
            print("inference time: \(inferenceTime) ms")
            let landmark = result.landmarks.first!
            let worldLandmark = result.worldLandmarks.first!
            return MediaPipePoseResult(landmarks2D: landmark, landmarks3D: worldLandmark)
        } catch {
            print(error)
            return nil
        }
    }
    
    private func imageGenerator(with videoAsset: AVAsset) -> AVAssetImageGenerator {
        let generator = AVAssetImageGenerator(asset: videoAsset)
        generator.requestedTimeToleranceBefore = CMTimeMake(value: 1, timescale: 25)
        generator.requestedTimeToleranceAfter = CMTimeMake(value: 1, timescale: 25)
        generator.appliesPreferredTrackTransform = true
        
        return generator
    }
}

struct MediaPipePoseResult {
    let landmarks2D: [NormalizedLandmark]
    let landmarks3D: [Landmark]
}

extension Landmark {
    var simdVector: SIMD3<Float> {
        return SIMD3<Float>(x, y, z)
    }
}

extension NormalizedLandmark {
    var cgPoint: CGPoint {
        return CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
}

