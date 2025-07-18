//
//import Vision
//import simd
//
//struct JointAngleCalculator {
//    /// Calculates the angle at a joint using its parent and child joints.
//    /// - Parameters:
//    ///   - proximal: the "parent" joint (e.g. hip)
//    ///   - joint: the joint where the angle is measured (e.g. knee)
//    ///   - distal: the "child" joint (e.g. ankle)
//    /// - Returns: Angle in degrees between the two vectors formed: proximal→joint and distal→joint
//    static func angleBetween(
//        joints: [VNHumanBodyPose3DObservation.JointName: VNRecognizedPoint3D],
//        proximalName: VNHumanBodyPose3DObservation.JointName,
//        jointName: VNHumanBodyPose3DObservation.JointName,
//        distalName: VNHumanBodyPose3DObservation.JointName
//    ) -> Double? {
//        guard let proximal = joints[proximalName],
//                  let joint = joints[jointName],
//                  let distal = joints[distalName] else {
//                return nil
//            }
//        let jointVec = joint.location
//        let proximalVec = proximal.location
//        let distalVec = distal.location
//
//        let vec1 = proximalVec - jointVec
//        let vec2 = distalVec - jointVec
//
//
//        let normalized1 = simd_normalize(vec1)
//        let normalized2 = simd_normalize(vec2)
//
//        let dot = simd_dot(normalized1, normalized2)
//        let clamped = max(min(dot, 1.0), -1.0) // clamp to avoid NaNs
//        let angleRadians = acos(clamped)
//        return Double(angleRadians * 180 / .pi)
//    }
//}
