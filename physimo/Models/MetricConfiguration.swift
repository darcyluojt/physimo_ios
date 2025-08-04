import Foundation
import UIKit
import Vision

enum AngleType: String, CaseIterable, Hashable {
    case kneeFlexion = "knee-flexion"
}

enum Side: String { case left, right, center }

enum Status: String { case healthy, injured }

struct MetricConfiguration: Identifiable, Hashable {
    let id = UUID()
    let angleType: AngleType
    let side: Side
    let joint: Joint
    var status: Status = .healthy
    
    var name: String {
        "\(side.rawValue.capitalized) \(angleType.rawValue.capitalized)"
    }
    
    func calculateAngle(from result: BodyDetectionResult) -> Float? {
        return result.angle(of: joint)
    }
}

extension MetricConfiguration {
    static let all: [MetricConfiguration] = [
        // Left knee flexion
        MetricConfiguration(
            angleType: .kneeFlexion,
            side: .left,
            joint: Joint(
                innerBone: Bone(
                    start: BodyPart.sided(.hip, .left),
                    end: BodyPart.sided(.knee, .left)
                ),
                outerBone: Bone(
                    start: BodyPart.sided(.knee, .left),
                    end: BodyPart.sided(.ankle, .left)
                )
            ),
            status: .healthy
        ),
        // Right knee flexion
        MetricConfiguration(
            angleType: .kneeFlexion,
            side: .right,
            joint: Joint(
                innerBone: Bone(
                    start: BodyPart.sided(.hip, .right),
                    end: BodyPart.sided(.knee, .right)
                ),
                outerBone: Bone(
                    start: BodyPart.sided(.knee, .right),
                    end: BodyPart.sided(.ankle, .right)
                )
            ),
            status: .injured
        )
    ]
}
