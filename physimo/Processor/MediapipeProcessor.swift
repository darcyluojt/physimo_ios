import UIKit
import MediaPipeTasksVision


func bodyPart(for index: Int) -> BodyPart? {
    switch index {
    case 23: return .sided(.hip, .left)
    case 24: return .sided(.hip, .right)
    case 25: return .sided(.knee, .left)
    case 26: return .sided(.knee, .right)
    case 27: return .sided(.ankle, .left)
    case 28: return .sided(.ankle, .right)
    // Add more cases as needed for other body parts
    default: return nil
    }
}

extension Landmark {
    var simdVector: SIMD3<Float> {
        SIMD3(x, y, z)
    }
}

extension NormalizedLandmark {
    var simdVector: SIMD3<Float> {
        SIMD3(x, y, 0)
    }

    var simd2Vector: SIMD2<Float> {
        SIMD2(x, y)
    }
}

class MediaPipeProcessor: ImageProcessor {
    private var poseLandmarker: PoseLandmarker

    init?(modelPath: String? = nil,
          numPoses: Int = 1,
          minPoseDetectionConfidence: Float = 0.5,
          minPosePresenceConfidence: Float = 0.5,
          minTrackingConfidence: Float = 0.5) {
        let options = PoseLandmarkerOptions()
        options.runningMode = .image
        options.numPoses = numPoses
        options.minPoseDetectionConfidence = minPoseDetectionConfidence
        options.minPosePresenceConfidence = minPosePresenceConfidence
        options.minTrackingConfidence = minTrackingConfidence
        guard let path = modelPath ?? Bundle.main.path(forResource: "pose_landmarker_heavy", ofType: "task") else {
            print("Model path is missing.")
            return nil
        }

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
