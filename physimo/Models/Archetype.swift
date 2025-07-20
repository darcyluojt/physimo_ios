import Foundation
import UIKit
import Vision

enum BodySide: String, Codable { case left, right }
enum Status:   String, Codable { case healthy, injured }

struct Archetype: Identifiable, Codable {
    let id: UUID
//    let userId: UUID
    let name: String
    let side: BodySide
    let slug: String
    let joints: [HumanBodyPose3DObservation.JointName]
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
    /// All the built-in archetypes your app ships with
    static let all: [Archetype] = [
        Archetype(
            id: UUID(),
            name: "knee-angle",
            side: .right,
            slug: "right-knee-angle",
            joints: [.rightHip, .rightKnee, .rightAnkle],
            status: .injured
        ),
        Archetype(
            id: UUID(),
            name: "knee-angle",
            side: .left,
            slug: "left-knee-angle",
            joints: [.leftHip, .leftKnee, .leftAnkle],
            status: .healthy
        ),
        // … any other default archetypes …
    ]
}
