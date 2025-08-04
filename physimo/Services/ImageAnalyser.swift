import Foundation
import SwiftUICore
import UIKit
import MediaPipeTasksVision
import Vision


struct ImageDisplayMetrics {
    let originalSize: CGSize
    let displayCanvasSize: CGSize
    let scaledImageSize: CGSize
    let scale: CGFloat
    let offset: CGPoint
    let image: UIImage
    
    init(image: UIImage, canvasSize: CGSize) {
        self.image = image
        self.displayCanvasSize = canvasSize
        
        // Calculate original image size for scaling
        self.originalSize = image.size
        
        // Calculate scaling ratios
        let widthRatio = canvasSize.width / originalSize.width
        let heightRatio = canvasSize.height / originalSize.height
        self.scale = min(heightRatio, widthRatio)
        
        // Calculate actual image display area within canvas
        self.scaledImageSize = CGSize(
            width: originalSize.width * scale, 
            height: originalSize.height * scale
        )
        
        // Calculate centering offset
        self.offset = CGPoint(
            x: (canvasSize.width - scaledImageSize.width) / 2,
            y: (canvasSize.height - scaledImageSize.height) / 2
        )
    }
    
    func printDebugInfo(prefix: String) {
        print("\(prefix) Debug:")
        print("  Image size: \(image.size)")
        print("  Image orientation: \(image.imageOrientation.rawValue)")
        print("  Calculated original size: \(originalSize)")
        print("  Display canvas size: \(displayCanvasSize)")
        print("  Width ratio: \(displayCanvasSize.width / originalSize.width), Height ratio: \(displayCanvasSize.height / originalSize.height)")
        print("  Selected scale: \(scale)")
        print("  Scaled image size: \(scaledImageSize)")
        print("  Offset: (\(offset.x), \(offset.y))")
    }
}

class ImageAnalyser {
    
    static func drawOverlays(
        in context: GraphicsContext,
        size: CGSize,
        for image: UIImage,
        from bodyResult: BodyDetectionResult?,
        color: Color = .red,
        prefix: String = "🎯 Pose"
    ) {
        guard let bodyResult = bodyResult else { return }
        drawBodyDetectionOverlays(
            in: context,
            size: size,
            for: image,
            from: bodyResult,
            color: color,
            prefix: prefix
        )
    }
    
    static func drawBodyDetectionOverlays(
        in context: GraphicsContext,
        size: CGSize,
        for image: UIImage,
        from bodyResult: BodyDetectionResult,
        color: Color = .red,
        prefix: String = "🎯 BodyDetection"
    ) {
        let landmarks = bodyResult.landmarks
        guard !landmarks.isEmpty else { return }
        
        let metrics = ImageDisplayMetrics(image: image, canvasSize: size)
        metrics.printDebugInfo(prefix: prefix)
        print("  Landmarks available: \(landmarks.keys.map { String(describing: $0) }.joined(separator: ", "))")
        
        let dots = bodyDetectionDots(from: bodyResult, metrics: metrics, prefix: prefix)
        
        // Draw dots
        for dot in dots {
            let rect = CGRect(x: dot.x - 3, y: dot.y - 3, width: 6, height: 6)
            context.fill(Path(ellipseIn: rect), with: .color(color))
        }
        
        print("  \(prefix) dots drawn: \(dots.count)")
    }
    
    
    static func bodyDetectionDots(
        from bodyResult: BodyDetectionResult,
        metrics: ImageDisplayMetrics,
        prefix: String
    ) -> [CGPoint] {
        print("🎯 \(prefix) Dots Debug:")
        print("  Overlay size: \(metrics.scaledImageSize)")
        print("  Offset: \(metrics.offset)")
        print("  Image orientation: \(metrics.image.imageOrientation.rawValue)")
        
        var dots: [CGPoint] = []
        
        for (bodyPart, landmark) in bodyResult.landmarks {
            // Use 2D position from BodyLandmark
            let x = CGFloat(landmark.position2D.x)
            let y = CGFloat(landmark.position2D.y)
            
            // Apply Y-flip for Apple Vision coordinate system (already handled in BodyDetectionResult conversion)
            let displayX = x * metrics.scaledImageSize.width + metrics.offset.x
            let displayY = y * metrics.scaledImageSize.height + metrics.offset.y
            
            dots.append(CGPoint(x: displayX, y: displayY))
            
            print("    \(bodyPart): (\(x), \(y)) -> (\(displayX), \(displayY))")
        }
        
        return dots
    }
    
}
