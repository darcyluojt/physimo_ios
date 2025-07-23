import CoreGraphics
import simd

/// A helper for calculating angles at a vertex formed by two points, in either 2D or 3D space.
struct AngleCalculationHelper {
    /// Calculates the planar angle (in degrees) at `vertex` formed by `pointA–vertex–pointB` in 2D.
    /// - Parameters:
    ///   - pointA: First point defining the angle.
    ///   - vertex: The vertex point where the angle is measured.
    ///   - pointB: Second point defining the angle.
    /// - Returns: Angle in degrees between the vectors `pointA - vertex` and `pointB - vertex`.
    static func calculateAngle2D(
        pointA: CGPoint,
        vertex: CGPoint,
        pointB: CGPoint
    ) -> Double {
        // Create vectors from vertex to each point
        let vectorA = CGVector(dx: pointA.x - vertex.x, dy: pointA.y - vertex.y)
        let vectorB = CGVector(dx: pointB.x - vertex.x, dy: pointB.y - vertex.y)
        
        // Dot product and magnitudes
        let dotProduct = Double(vectorA.dx * vectorB.dx + vectorA.dy * vectorB.dy)
        let magnitudeA = sqrt(Double(vectorA.dx * vectorA.dx + vectorA.dy * vectorA.dy))
        let magnitudeB = sqrt(Double(vectorB.dx * vectorB.dx + vectorB.dy * vectorB.dy))
        
        // Guard against zero-length vectors
        guard magnitudeA > 0, magnitudeB > 0 else { return 0 }
        
        // Cosine of the angle
        let cosAngle = dotProduct / (magnitudeA * magnitudeB)
        // Clamp to [-1, 1] to avoid NaN from rounding errors
        let clamped = min(max(cosAngle, -1.0), 1.0)
        // Compute angle in radians and convert to degrees
        let angleRadians = acos(clamped)
        let angleDegrees = angleRadians * 180.0 / .pi
        return 180 - angleDegrees
    }


    static func calculateAngle3D(
        pointA: SIMD3<Float>,
        vertex: SIMD3<Float>,
        pointB: SIMD3<Float>
    ) -> Double {
        // Create vectors from vertex to each point
        let vectorA = pointA - vertex
        let vectorB = pointB - vertex
        
        // Dot product and magnitudes
        let dotProduct = simd_dot(vectorA, vectorB)
        let magnitudeA = simd_length(vectorA)
        let magnitudeB = simd_length(vectorB)
        
        // Guard against zero-length vectors
        guard magnitudeA > 0, magnitudeB > 0 else { return 0 }
        
        // Cosine of the angle
        let cosAngle = dotProduct / (magnitudeA * magnitudeB)
        // Clamp to [-1, 1]
        let clamped = min(max(Double(cosAngle), -1.0), 1.0)
        // Compute angle in radians and convert to degrees
        let angleRadians = acos(clamped)
        let angleDegrees = angleRadians * 180.0 / .pi
        return 180 - angleDegrees
    }
}

