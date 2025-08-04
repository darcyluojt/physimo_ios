import Foundation
import simd
import Vision
import MediaPipeTasksVision

struct BodyLandmark {
    let position2D: SIMD3<Float>
    let position3D: SIMD3<Float>

    init(position3D: SIMD3<Float>, position2D: SIMD2<Float>? = nil) {
        self.position3D = position3D
        if let pos2D = position2D {
            self.position2D = SIMD3(pos2D.x, pos2D.y, 0)
        } else {
            self.position2D = SIMD3(position3D.x, position3D.y, 0)
        }
    }
}

enum SidedBodyPart: String, CaseIterable, Hashable {
    case ankle, knee, hip, shoulder, elbow, wrist
}

enum CentralBodyPart: String, CaseIterable, Hashable {
    case head, neck, root, spine
}

enum BodyPartSide: String, Hashable {
    case left, right, central
    
    var opposite: BodyPartSide? {
        switch self {
        case .left: return .right
        case .right: return .left
        case .central: return nil
        }
    }
}

enum BodyPart: Hashable {
    case sided(SidedBodyPart, BodyPartSide)
    case central(CentralBodyPart)
}

struct Bone: Hashable {
    let start: BodyPart
    let end: BodyPart
}

struct Joint: Hashable {
    let innerBone: Bone
    let outerBone: Bone
}

struct BodyDetectionResult {
    var landmarks: [BodyPart: BodyLandmark] = [:]
    
    func vector(for bone: Bone) -> SIMD3<Float>? {
        guard let startLandmark = landmarks[bone.start],
              let endLandmark = landmarks[bone.end] else {
            return nil
        }
        return endLandmark.position3D - startLandmark.position3D
    }
    
    func angle(of joint: Joint) -> Float? {
        guard let vec1 = vector(for: joint.innerBone),
              let vec2 = vector(for: joint.outerBone) else {
            return nil
        }

        let length1 = simd_length(vec1)
        let length2 = simd_length(vec2)
        guard length1 > 0 && length2 > 0 else {
            return nil
        }

        let dotProduct = simd_dot(simd_normalize(vec1), simd_normalize(vec2))
        let clampedDot = max(-1.0, min(1.0, dotProduct))
        return acos(clampedDot) * 180 / .pi
    }
}

extension BodyDetectionResult {
    
    func calculateMetrics(source: Metric.Source) -> [Metric] {
        return MetricConfiguration.all.compactMap { config in
            guard let angleValue = config.calculateAngle(from: self) else {
                return nil
            }
            
            return Metric(
                id: UUID(),
                configuration: config,
                source: source,
                value: Double(angleValue),
                accuracy: nil,
                ignored: false,
                videoTimestamp: nil,
                phtoTimestamp: Date()
            )
        }
    }
    
    static func from(mediaPipe2D: [NormalizedLandmark]) -> BodyDetectionResult {
        var result = BodyDetectionResult()
        
        for (index, landmark) in mediaPipe2D.enumerated() {
            if let bodyPart = MediaPipeIndex(rawValue: index)?.toBodyPart() {
                let position2D = SIMD2<Float>(landmark.x, landmark.y)
                let position3D = SIMD3<Float>(landmark.x, landmark.y, 0)
                
                result.landmarks[bodyPart] = BodyLandmark(position3D: position3D, position2D: position2D)
            }
        }
        
        return result
    }
    
    static func from(mediaPipe2D: [NormalizedLandmark], imageOrientation: UIImage.Orientation) -> BodyDetectionResult {
        var result = BodyDetectionResult()
        
        for (index, landmark) in mediaPipe2D.enumerated() {
            if let bodyPart = MediaPipeIndex(rawValue: index)?.toBodyPart() {
                // Transform coordinates based on image orientation
                let transformedCoords = transformCoordinates(
                    x: landmark.x, 
                    y: landmark.y, 
                    orientation: imageOrientation
                )
                
                let position2D = SIMD2<Float>(transformedCoords.x, transformedCoords.y)
                let position3D = SIMD3<Float>(transformedCoords.x, transformedCoords.y, 0)
                
                result.landmarks[bodyPart] = BodyLandmark(position3D: position3D, position2D: position2D)
            }
        }
        
        return result
    }
    
    private static func transformCoordinates(x: Float, y: Float, orientation: UIImage.Orientation) -> (x: Float, y: Float) {
        switch orientation {
        case .up:
            return (x, y)
        case .right: // 90° clockwise
            return (1.0 - y, x)
        case .down: // 180°
            return (1.0 - x, 1.0 - y)
        case .left: // 90° counter-clockwise
            return (y, 1.0 - x)
        case .upMirrored:
            return (1.0 - x, y)
        case .rightMirrored:
            return (1.0 - y, 1.0 - x)
        case .downMirrored:
            return (x, 1.0 - y)
        case .leftMirrored:
            return (y, x)
        @unknown default:
            return (x, y)
        }
    }
    
    static func from(mediaPipe3D: [SIMD3<Float>]) -> BodyDetectionResult {
        var result = BodyDetectionResult()
        
        for (index, position) in mediaPipe3D.enumerated() {
            if let bodyPart = MediaPipeIndex(rawValue: index)?.toBodyPart() {
                result.landmarks[bodyPart] = BodyLandmark(position3D: position)
            }
        }
        
        return result
    }
}

enum MediaPipeIndex: Int {
    case leftHip = 23
    case rightHip = 24
    case leftKnee = 25
    case rightKnee = 26
    case leftAnkle = 27
    case rightAnkle = 28
    case leftShoulder = 11
    case rightShoulder = 12
    case leftElbow = 13
    case rightElbow = 14
    case leftWrist = 15
    case rightWrist = 16
    
    func toBodyPart() -> BodyPart {
        switch self {
        case .leftHip: return .sided(.hip, .left)
        case .rightHip: return .sided(.hip, .right)
        case .leftKnee: return .sided(.knee, .left)
        case .rightKnee: return .sided(.knee, .right)
        case .leftAnkle: return .sided(.ankle, .left)
        case .rightAnkle: return .sided(.ankle, .right)
        case .leftShoulder: return .sided(.shoulder, .left)
        case .rightShoulder: return .sided(.shoulder, .right)
        case .leftElbow: return .sided(.elbow, .left)
        case .rightElbow: return .sided(.elbow, .right)
        case .leftWrist: return .sided(.wrist, .left)
        case .rightWrist: return .sided(.wrist, .right)
        }
    }
}

extension HumanBodyPoseObservation.PoseJointName {
    func toBodyPart() -> BodyPart {
        switch self {
        case .leftHip: return .sided(.hip, .left)
        case .rightHip: return .sided(.hip, .right)
        case .leftKnee: return .sided(.knee, .left)
        case .rightKnee: return .sided(.knee, .right)
        case .leftAnkle: return .sided(.ankle, .left)
        case .rightAnkle: return .sided(.ankle, .right)
        case .leftShoulder: return .sided(.shoulder, .left)
        case .rightShoulder: return .sided(.shoulder, .right)
        case .leftElbow: return .sided(.elbow, .left)
        case .rightElbow: return .sided(.elbow, .right)
        case .leftWrist: return .sided(.wrist, .left)
        case .rightWrist: return .sided(.wrist, .right)
        default: return .central(.spine)
        }
    }
}

extension HumanBodyPose3DObservation.JointName {
    func toBodyPart() -> BodyPart {
        switch self {
        case .leftHip: return .sided(.hip, .left)
        case .rightHip: return .sided(.hip, .right)
        case .leftKnee: return .sided(.knee, .left)
        case .rightKnee: return .sided(.knee, .right)
        case .leftAnkle: return .sided(.ankle, .left)
        case .rightAnkle: return .sided(.ankle, .right)
        case .leftShoulder: return .sided(.shoulder, .left)
        case .rightShoulder: return .sided(.shoulder, .right)
        case .leftElbow: return .sided(.elbow, .left)
        case .rightElbow: return .sided(.elbow, .right)
        case .leftWrist: return .sided(.wrist, .left)
        case .rightWrist: return .sided(.wrist, .right)
        default: return .central(.spine)
        }
    }
}
