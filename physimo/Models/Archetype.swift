import Foundation
import UIKit
import Vision

enum BodySide: String, Codable { case left, right }
enum Status:   String, Codable { case healthy, injured }

struct JointReference: Codable {
    var appleJoint: HumanBodyPose3DObservation.JointName? // For Vision
    var mediaPipeIndex: Int?                              // For MediaPipe
}

struct Archetype: Identifiable, Codable {
    let id: UUID
//    let userId: UUID
    let name: String
    let side: BodySide
    let slug: String
    let joints: [JointReference]
    var status: Status
}


enum Joints: String, Codable {
    case hip
    case knee
    case ankle
    case shoulder
    case elbow
}


extension Archetype {
    static let all: [Archetype] = [
        Archetype(
            id: UUID(),
            name: "knee-angle",
            side: .right,
            slug: "right-knee-angle",
            joints: [
                JointReference(appleJoint: .rightHip,  mediaPipeIndex: 24),
                JointReference(appleJoint: .rightKnee, mediaPipeIndex: 26),
                JointReference(appleJoint: .rightAnkle, mediaPipeIndex: 28)
            ],
            status: .injured
        ),
        Archetype(
            id: UUID(),
            name: "knee-angle",
            side: .left,
            slug: "left-knee-angle",
            joints: [
                JointReference(appleJoint: .leftHip,  mediaPipeIndex: 23),
                JointReference(appleJoint: .leftKnee, mediaPipeIndex: 25),
                JointReference(appleJoint: .leftAnkle, mediaPipeIndex: 27)
            ],
            status: .healthy
        )
    ]
}

