import UIKit

protocol ImageProcessor {
    func process(image: UIImage) -> [String: BodyDetectionResult]
}
