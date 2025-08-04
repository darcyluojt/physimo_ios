import UIKit
import MediaPipeTasksVision

class MediapipeProcessor: NSObject {
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
        minTrackingConfidence: Float) -> MediapipeProcessor? {
            let MediapipeProcessor = MediapipeProcessor(
                modelPath: modelPath,
                runningMode: .image,
                numPoses: numPoses,
                minPoseDetectionConfidence: minPoseDetectionConfidence,
                minPosePresenceConfidence: minPosePresenceConfidence,
                minTrackingConfidence: minTrackingConfidence)
<<<<<<< HEAD

            return poseLandmarkerService
=======

            return MediapipeProcessor
>>>>>>> a43335a (streamline api output to body detection result)
        }

    func detect(image: MPImage) -> MediaPipePoseResult? {
        do {
            let startDate = Date()
            guard let result = try poseLandmarker?.detect(image: image),
                  let landmark = result.landmarks.first,
                  let worldLandmark = result.worldLandmarks.first
            else {
                return nil
            }
            let inferenceTime = Date().timeIntervalSince(startDate) * 1000
            print("inference time: \(inferenceTime) ms")
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

    func toBodyDetectionResult2D(imageOrientation: UIImage.Orientation = .up) -> BodyDetectionResult {
        return BodyDetectionResult.from(mediaPipe2D: landmarks2D, imageOrientation: imageOrientation)
    }

    func toBodyDetectionResult3D() -> BodyDetectionResult {
        let jointVectors = landmarks3D.map { SIMD3<Float>($0.x, $0.y, $0.z) }
        return BodyDetectionResult.from(mediaPipe3D: jointVectors)
    }

}

class MediaPipeProcessor: ImageProcessor {
    private var poseLandmarker: PoseLandmarker

    init?(modelPath: String? = nil,
          numPoses: Int = 1,
          minPoseDetectionConfidence: Float = 0.5,
          minPosePresenceConfidence: Float = 0.5,
          minTrackingConfidence: Float = 0.5) {

        guard let modelPath = modelPath ?? Bundle.main.path(forResource: "pose_landmarker_heavy", ofType: "task") else {
            print("Model path is missing.")
            return nil
        }

        let options = PoseLandmarkerOptions()
        options.baseOptions.modelAssetPath = modelPath
        options.runningMode = .image
        options.numPoses = numPoses
        options.minPoseDetectionConfidence = minPoseDetectionConfidence
        options.minPosePresenceConfidence = minPosePresenceConfidence
        options.minTrackingConfidence = minTrackingConfidence

        do {
            poseLandmarker = try PoseLandmarker(options: options)
        } catch {
            print("Failed to initialize PoseLandmarker:", error)
            return nil
        }
    }

    func process(image: UIImage) -> [String: BodyDetectionResult] {
        do {
            let mpImage = try MPImage(uiImage: image)
            let result = try poseLandmarker.detect(image: mpImage)

            guard let landmarks2D = result.landmarks.first,
                  let landmarks3D = result.worldLandmarks.first else {
                return [:]
            }

            var mapped: [BodyPart: BodyLandmark] = [:]
            for (i, landmark3D) in landmarks3D.enumerated() {
                guard i < landmarks2D.count, let bodyPart = bodyPart(for: i) else { continue }
                let landmark2D = landmarks2D[i]
                let position3D = landmark3D.simdVector
                let position2D = SIMD2<Float>(landmark2D.x, landmark2D.y)
                mapped[bodyPart] = BodyLandmark(position3D: position3D, position2D: position2D)
            }

            return ["default": BodyDetectionResult(landmarks: mapped)]
        } catch {
            print("Pose detection error:", error)
            return [:]
        }
    }


}
