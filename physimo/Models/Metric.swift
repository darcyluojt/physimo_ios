struct JointMetric: Identifiable {
    let jointConfiguration: JointConfiguration
    let modelName: String
    let detectedAngle: Float?
    let id: String

    init(from config: JointConfiguration, modelName: String, detectionResult: BodyDetectionResult) {
        self.jointConfiguration = config
        self.modelName = modelName
        self.detectedAngle = detectionResult.angle(of: config.joint)
        self.id =  "\(modelName) - \(jointConfiguration.name)"
    }
}
