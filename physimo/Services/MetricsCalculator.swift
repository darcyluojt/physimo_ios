import Foundation
import Vision
import simd

struct MetricsCalculator {
    static func calculateKneeAngles(
        from result: DetectionResult,
        uploadId: UUID,
        archetypes: [Archetype] = Archetype.all,
        source: Metric.Source
    ) -> [Metric] {
        let allJoints = result.allJoints()
        var metrics: [Metric] = []
        
        let archetypes = archetypes.filter { $0.name == "knee-angle" }
        for archetype in archetypes {
            let keys = archetype.joints
            guard
                let parentPoint = allJoints[keys[0]],
                let pivotPoint = allJoints[keys[1]],
                let childPoint = allJoints[keys[2]]
            else { continue }
            
            let parentPos = parentPoint.position[3].xyz
            let pivotPos  = pivotPoint.position[3].xyz
            let childPos  = childPoint.position[3].xyz
            
            
            let v1 = parentPos - pivotPos
            let v2 = childPos - pivotPos
            
            
            let cosθ = simd_dot(simd_normalize(v1), simd_normalize(v2))
            let clamped = simd_clamp(cosθ, -1.0, 1.0)
            let angleDeg = acos(clamped) * 180 / .pi
            
            
            let metric = Metric(
                id: UUID(),
                uploadId: uploadId,
                archetype: archetype,
                source: source,
                value: Double(180 - angleDeg),
                accuracy: 1.0
            )
            metrics.append(metric)
        }
        return metrics
    }
    
    static func calculateKneeAngles2D (
        from result: DetectionResult2D,
        uploadId: UUID,
        archetypes: [Archetype] = Archetype.all,
        source: Metric.Source
    ) -> [Metric] {
        let allJoints = result.allJoints()
        var metrics: [Metric] = []
        
        let archetypes = archetypes.filter { $0.name == "knee-angle" }
        for archetype in archetypes {
            let keys = archetype.joints
            guard let parentName = HumanBodyPoseObservation.JointName(rawValue: keys[0].rawValue),
                  let pivotName = HumanBodyPoseObservation.JointName(rawValue: keys[1].rawValue),
                  let childName = HumanBodyPoseObservation.JointName(rawValue: keys[2].rawValue),
                  let parent = allJoints[parentName],
                  let pivot = allJoints[pivotName],
                  let child = allJoints[childName]
            else { continue }
            let confidence = min(parent.confidence, pivot.confidence, child.confidence)
            let v1 = simd_float2(Float(parent.location.x - pivot.location.x), Float(parent.location.y - pivot.location.y))
            let v2 = simd_float2(Float(child.location.x - pivot.location.x), Float(child.location.y - pivot.location.y))

            let cosθ = simd_dot(simd_normalize(v1), simd_normalize(v2))
            let clamped = simd_clamp(cosθ, -1.0, 1.0)
            let angleDeg = acos(clamped) * 180 / .pi
            let metric = Metric(
                            id: UUID(),
                            uploadId: uploadId,
                            archetype: archetype,
                            source: source,
                            value: Double(180 - angleDeg),
                            accuracy: Double(confidence)
                        )
                        metrics.append(metric)
                    }

                    return metrics
                }


}
    
extension SIMD4 where Scalar == Float {
  /// Drop the w component and return the (x,y,z) vector.
  var xyz: SIMD3<Float> {
    return SIMD3<Float>(x, y, z)
  }
}

//.rightLeg, .leftLeg
// let recognizedPoints = try observation.recognizedPoints(.rightLeg)
//pointInImage(_:)
 

//class HumanBodyPose3DDetector: NSObject, ObservableObject {
//    
//    @Published var humanObservation: VNHumanBodyPose3DObservation? = nil
//    var fileURL: URL? = URL(string: "")
//    
//    public func calculatedLocalAngleToParent(joint: VNHumanBodyPose3DObservation.JointName) -> simd_float3 {
//        var angleVector: simd_float3 = simd_float3()
//        do {
//            if let observation = self.humanObservation {
//                let recognizedPoint = try observation.recognizedPoint(joint)
//                let childPosition = recognizedPoint.localPosition
//                let translationC = childPosition.translationVector
////                / Rotation for x, y, z
//                // Rotate 90 from default orientation of node, yaw and pitch connect child to parent
//                let pitch = (Float.pi / 2)
//                let yaw = acos(translationC.z / simd_length(translationC) )
//                let roll = atan2((translationC.y), (translationC.x))
//                angleVector = simd_float3(pitch, yaw, roll)
//            }
//        } catch {
//            print("Unable to return point: \(error).")
//    }
//        return angleVector
//}

