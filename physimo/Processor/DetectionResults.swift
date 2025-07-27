import simd

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
    case ankle, knee, hip
}

enum CentralBodyPart: String, CaseIterable, Hashable {
    case head, stomach, neck
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

enum BodyPart : Hashable {
    case sided(SidedBodyPart, BodyPartSide)
    case central(CentralBodyPart)
    
    init?(from string: String) {
        let parts = string.lowercased().split(separator: "_")
        
        if parts.count == 2,
           let side = BodyPartSide(rawValue: String(parts[0])),
           let part = SidedBodyPart(rawValue: String(parts[1])) {
            self = .sided(part, side)
        } else if parts.count == 2, parts[0] == "central",
                  let part = CentralBodyPart(rawValue: String(parts[1])) {
            self = .central(part)
        } else {
            return nil
        }
    }
    
    var stringValue: String {
        switch self {
        case .sided(let part, let side):
            return "\(side.rawValue)_\(part.rawValue)"
        case .central(let part):
            return "central_\(part.rawValue)"
        }
    }
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
        let clampedDot = max(-1.0, min(1.0, dotProduct)) // Avoid NaN due to floating-point errors
        return acos(clampedDot)  * 180 / .pi
    }
}

