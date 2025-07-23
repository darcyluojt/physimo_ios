import Foundation
import UIKit
import Vision

enum BodySide: String, Codable { case left, right }
enum Status:   String, Codable { case healthy, injured }

struct JointReference: Codable {
    var apple3dJoint: HumanBodyPose3DObservation.JointName? // For Vision
    var apple2dJoint: HumanBodyPoseObservation.JointName?
    var mediaPipeIndex: Int?                              // For MediaPipe
}

enum Side: String, Codable, Equatable, Hashable {
    case left, right
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



extension Archetype {
    static let all: [Archetype] = [
        Archetype(
            id: UUID(),
            name: "knee-angle",
            side: .right,
            slug: "right-knee-angle",
            joints: [
                JointReference(apple3dJoint: .rightHip,  apple2dJoint: .rightHip, mediaPipeIndex: 24),
                JointReference(apple3dJoint: .rightKnee, apple2dJoint: .rightKnee, mediaPipeIndex: 26),
                JointReference(apple3dJoint: .rightAnkle, apple2dJoint: .rightAnkle, mediaPipeIndex: 28)
            ],
            status: .injured
        ),
        Archetype(
            id: UUID(),
            name: "knee-angle",
            side: .left,
            slug: "left-knee-angle",
            joints: [
                JointReference(apple3dJoint: .leftHip,  apple2dJoint: .leftHip, mediaPipeIndex: 23),
                JointReference(apple3dJoint: .leftKnee, apple2dJoint: .leftKnee, mediaPipeIndex: 25),
                JointReference(apple3dJoint: .leftAnkle, apple2dJoint: .leftAnkle, mediaPipeIndex: 27)
            ],
            status: .healthy
        )
    ]
}

