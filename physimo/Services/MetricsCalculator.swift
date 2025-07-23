import Foundation
import Vision
import simd

struct MetricsCalculator {
    static func calculateKneeAngles(
        fromApple3D result: DetectionResult,
        uploadId: UUID,
        archetypes: [Archetype] = Archetype.all,
        source: Metric.Source
    ) -> [Metric] {
        return calculate(
            uploadId: uploadId,
            archetypes: archetypes,
            source: source,
            jointCoordsList: archetypes.map { fetchApple3DJoints(from: result, archetype: $0) },
            jointConfidencesList: nil,
            angleFunc: AngleCalculationHelper.calculateAngle3D
        )
    }
    
    static func calculateKneeAngles(
        fromMP3D landmarks: [SIMD3<Float>],
        confidenceList: [Double]?,
        uploadId: UUID,
        archetypes: [Archetype] = Archetype.all,
        source: Metric.Source
    ) -> [Metric] {
        let pairs: [([SIMD3<Float>], [Double]?)] = archetypes.map {
            fetchMP3DJoints(from: landmarks, confidenceList: confidenceList, archetype: $0)
        }
        let jointGroups = pairs.map {$0.0}
        let confidenceGroups : [[Double]]? = confidenceList != nil
            ? pairs.map { $0.1 ?? [0.0, 0.0, 0.0] } // default fallback if needed
            : nil
        return calculate(
            uploadId: uploadId,
            archetypes: archetypes,
            source: source,
            jointCoordsList: jointGroups,
            jointConfidencesList: confidenceGroups,
            angleFunc: AngleCalculationHelper.calculateAngle3D
        )
    }
    
    static func CalculateKneeAngles2D(
        fromApple2D result: DetectionResult2D,
        uploadId: UUID,
        archetypes: [Archetype] = Archetype.all,
        source: Metric.Source
    ) -> [Metric] {
        let pairs: [([CGPoint], [Double]?)] = archetypes.map {
            fetchApple2DJoints(from: result, archetype: $0)
        }
        let jointGroups = pairs.map {$0.0}
        let confidenceGroups = pairs.map { $0.1 ?? [0.0, 0.0, 0.0] }
        return calculate(
            uploadId: uploadId,
            archetypes: archetypes,
            source: source,
            jointCoordsList: jointGroups,
            jointConfidencesList: confidenceGroups,
            angleFunc: AngleCalculationHelper.calculateAngle2D
        )
    }
    
    static func CalculateKneeAngles2D(
        fromMP2D points: [CGPoint],
        confidenceList: [Double]?,
        uploadId: UUID,
        archetypes: [Archetype] = Archetype.all,
        source: Metric.Source
    ) -> [Metric] {
        let pairs: [([CGPoint], [Double]?)] = archetypes.map {
            fetchMediaPipe2DJoints(from: points, confidenceList: confidenceList, archetype: $0)
        }
        let jointGroups = pairs.map {$0.0}
        let confidenceGroups : [[Double]]? = confidenceList != nil
            ? pairs.map { $0.1 ?? [0.0, 0.0, 0.0] } // default fallback if needed
            : nil
        return calculate(
            uploadId: uploadId,
            archetypes: archetypes,
            source: source,
            jointCoordsList: jointGroups,
            jointConfidencesList: confidenceGroups,
            angleFunc: AngleCalculationHelper.calculateAngle2D
        )
    }
    
    
    private static func calculate<T>(
        uploadId: UUID,
        archetypes: [Archetype],
        source: Metric.Source,
        jointCoordsList: [[T]],
        jointConfidencesList: [[Double]]? = nil,
        angleFunc: (T, T, T) -> Double
    ) -> [Metric] {
        var metrics: [Metric] = []
        for (index, archetype) in archetypes.enumerated() {
            let coords = jointCoordsList[index]
            guard coords.count == 3 else { continue }
            let angle = angleFunc(coords[0], coords[1], coords[2])
            let accuracy: Double? = jointConfidencesList?[index].min()
            let metric = Metric(
                id: UUID(),
                uploadId: uploadId,
                archetype: archetype,
                source: source,
                value: angle,
                accuracy: accuracy // Accuracy can be calculated if needed
            )
            metrics.append(metric)
        }
        return metrics
    }
    
    
    private static func fetchApple3DJoints(
        from result: DetectionResult,
        archetype: Archetype
    ) -> [SIMD3<Float>] {
        // allJoints returns a map of JointName to Joint3D
        let jointsDict = result.allJoints()
        return archetype.joints.compactMap { ref in
            guard let name = ref.apple3dJoint,
                  let joint3D = jointsDict[name] else { return .zero }
            let t = joint3D.position.columns.3
            print("Apple 3D Joint \(name) position: \(t)")
            return SIMD3<Float>(t.x, t.y, t.z)
        }
    }
    
    private static func fetchMP3DJoints(
        from landmarks: [SIMD3<Float>],
        confidenceList: [Double]?,
        archetype: Archetype
    ) -> ([SIMD3<Float>],[Double]?) {
        var coords: [SIMD3<Float>] = []
        var confidences: [Double] = []
        for ref in archetype.joints {
            let idx = ref.mediaPipeIndex!
            coords.append(landmarks[idx])
            confidences.append(confidenceList?[idx] ?? 0.0)
            print("MP3D landmark: \(idx), \(landmarks[idx]), \(confidenceList?[idx] ?? 0.0)")
        }
        
        return (coords, confidences)
    }
    
    private static func fetchApple2DJoints(
        from observation: DetectionResult2D,
        archetype: Archetype
    ) -> ([CGPoint],[Double]?) {
        // `allJoints()` returns a dictionary mapping JointName to VNRecognizedPoint
        let allJoints = observation.allJoints()
        var locations: [CGPoint] = []
        var confidenceList: [Double] = []
        for ref in archetype.joints {
            let name = ref.apple2dJoint!
            let recognizedPoint = allJoints[name]!
            locations.append(recognizedPoint.location.cgPoint)
            confidenceList.append(Double(recognizedPoint.confidence))
            print("App2D landmark: \(name), \(recognizedPoint.location.cgPoint), \(Double(recognizedPoint.confidence))")
        }
        return (locations, confidenceList)
    }
    
    private static func fetchMediaPipe2DJoints(
        from points: [CGPoint],
        confidenceList: [Double]?,
        archetype: Archetype
    ) -> ([CGPoint],[Double]?) {
        var coords: [CGPoint] = []
        var visibilities: [Double] = []
        for ref in archetype.joints {
            let idx = ref.mediaPipeIndex!
            coords.append(points[idx])
            visibilities.append(confidenceList?[idx] ?? 0.0)
            print("MP2D landmark: \(idx), \(points[idx]), \(confidenceList?[idx] ?? 0.0)")
        }
        return (coords, confidenceList != nil ? visibilities : nil)
    }
}
//extension SIMD4 where Scalar == Float {
//  /// Drop the w component and return the (x,y,z) vector.
//  var xyz: SIMD3<Float> {
//    return SIMD3<Float>(x, y, z)
//  }
//}
