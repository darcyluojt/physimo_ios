import UIKit

class ImageProcessorModel {
    private var processors: [String: ImageProcessor]
    
    init(processors: [String: ImageProcessor] = [:]) {
        self.processors = processors
    }
    
    init() {
        self.processors = [:]
        if let mediaPipe = MediaPipeProcessor() {
            self.processors["MediaPipe"] = mediaPipe
        }
    }
    func addProcessor(key: String, processor: ImageProcessor) {
        processors[key] = processor
    }
    
    func process(image: UIImage) -> [String: BodyDetectionResult] {
        var results: [String: BodyDetectionResult] = [:]
        for (key, processor) in processors {
            if let result = processor.process(image: image)[key] {
                results[key] = result
            }
        }
        return results
    }
}
