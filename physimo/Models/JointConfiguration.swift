enum JointType: String, CaseIterable, Hashable {
    case knee
}

enum Status: String {
    case healthy,injured
}

struct JointConfiguration {
    let joint: Joint
    let name: String // Example: Left knee
    let JointType : JointType // Left knee
}


extension JointConfiguration {
    static let all: [JointConfiguration] = [
        JointConfiguration(
            joint: Joint(
                innerBone: Bone(start: .sided(.hip, .right), end: .sided(.knee, .right)),
                outerBone: Bone(start: .sided(.knee, .right), end: .sided(.ankle, .right))
            ),
            name: "Right knee",
            JointType: .knee
        ),
        JointConfiguration(
            joint: Joint(
                innerBone: Bone(start: .sided(.hip, .left), end: .sided(.knee, .left)),
                outerBone: Bone(start: .sided(.knee, .left), end: .sided(.ankle, .left))
            ),
            name: "Left knee",
            JointType: .knee
        )
    ]
}
