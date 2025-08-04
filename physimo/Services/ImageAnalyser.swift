import Foundation
import SwiftUICore
import UIKit
import MediaPipeTasksVision
import Vision

struct Line {
    let from: CGPoint
    let to: CGPoint
}


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
    
    // MediaPipe-specific drawing method with full 33 landmark support
    static func drawMediaPipeOverlays(
        in context: GraphicsContext,
        size: CGSize,
        for image: UIImage,
        fromMP2D: [NormalizedLandmark]? = nil,
        color: Color = .red,
        prefix: String = "🔍 MediaPipe"
    ) {
        guard let landmarks = fromMP2D, !landmarks.isEmpty else { return }
        
        let metrics = ImageDisplayMetrics(image: image, canvasSize: size)
        metrics.printDebugInfo(prefix: prefix)
        print("  MediaPipe landmarks count: \(landmarks.count)")
        
        let dots = mediaPipeDots(
            fromMP2D: landmarks,
            metrics: metrics,
            prefix: prefix
        )
        
        // Draw bones (connections between landmarks)
        let bones = mediaPipeBones(dots: dots)
        for bone in bones {
            var path = Path()
            path.move(to: bone.from)
            path.addLine(to: bone.to)
            context.stroke(path, with: .color(color), lineWidth: 2)
        }
        
        // Draw dots on top of bones
        for dot in dots {
            let rect = CGRect(x: dot.x - 2, y: dot.y - 2, width: 4, height: 4)
            context.fill(Path(ellipseIn: rect), with: .color(color))
        }
        
        print("  \(prefix) dots drawn: \(dots.count), bones drawn: \(bones.count)")
    }
    
    // Apple Vision drawing method (keeps current BodyDetectionResult approach)
    static func drawAppleOverlays(
        in context: GraphicsContext,
        size: CGSize,
        for image: UIImage,
        from bodyResult: BodyDetectionResult?,
        color: Color = .blue,
        prefix: String = "🍎 Apple"
    ) {
        guard let bodyResult = bodyResult else { return }
        let landmarks = bodyResult.landmarks
        guard !landmarks.isEmpty else { return }
        
        let metrics = ImageDisplayMetrics(image: image, canvasSize: size)
        metrics.printDebugInfo(prefix: prefix)
        print("  Landmarks available: \(landmarks.keys.map { String(describing: $0) }.joined(separator: ", "))")
        
        let dots = appleDots(from: bodyResult, metrics: metrics, prefix: prefix)
        
        // Draw dots
        for dot in dots {
            let rect = CGRect(x: dot.x - 3, y: dot.y - 3, width: 6, height: 6)
            context.fill(Path(ellipseIn: rect), with: .color(color))
        }
        
        print("  \(prefix) dots drawn: \(dots.count)")
    }
    
    // MediaPipe coordinate transformation (preserves all 33 landmarks)
    static func mediaPipeDots(
        fromMP2D: [NormalizedLandmark],
        metrics: ImageDisplayMetrics,
        prefix: String
    ) -> [CGPoint] {
        print("🎯 \(prefix) Dots Debug:")
        print("  Overlay size: \(metrics.scaledImageSize)")
        print("  Offset: \(metrics.offset)")
        print("  Image orientation: \(metrics.image.imageOrientation.rawValue)")
        
        let dots: [CGPoint] = fromMP2D.map { landmark in
            let x = CGFloat(landmark.x)
            let y = CGFloat(landmark.y)
            
            // Transform coordinates based on image orientation using your proven logic
            let (transformedX, transformedY) = transformCoordinates(
                x: x, y: y,
                orientation: metrics.image.imageOrientation,
                cgImageSize: metrics.image.cgImage.map { CGSize(width: $0.width, height: $0.height) } ?? metrics.image.size,
                uiImageSize: metrics.image.size,
                displaySize: metrics.scaledImageSize
            )
            
            // Apply offset for centering
            return CGPoint(
                x: transformedX + metrics.offset.x,
                y: transformedY + metrics.offset.y
            )
        }
        
        // Debug output for first few landmarks
        for i in 0..<min(3, dots.count) {
            let original = fromMP2D[i]
            print("    [\(i)] Original: (\(original.x), \(original.y)) -> Final: (\(dots[i].x), \(dots[i].y))")
        }
        
        return dots
    }
    
    // Apple Vision coordinate handling (simpler since it respects orientation)
    static func appleDots(
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
            // Use 2D position from BodyLandmark (already has Y-flip applied in Vision2DProcessor)
            let x = CGFloat(landmark.position2D.x)
            let y = CGFloat(landmark.position2D.y)
            
            let displayX = x * metrics.scaledImageSize.width + metrics.offset.x
            let displayY = y * metrics.scaledImageSize.height + metrics.offset.y
            
            dots.append(CGPoint(x: displayX, y: displayY))
            
            print("    \(bodyPart): (\(x), \(y)) -> (\(displayX), \(displayY))")
        }
        
        return dots
    }
    
    // Your proven coordinate transformation logic
    private static func transformCoordinates(
        x: CGFloat,
        y: CGFloat,
        orientation: UIImage.Orientation,
        cgImageSize: CGSize,
        uiImageSize: CGSize,
        displaySize: CGSize
    ) -> (CGFloat, CGFloat) {
        // MediaPipe processes raw CGImage data and returns normalized coordinates (0-1)
        // based on the raw pixel dimensions. We need to transform these to match
        // the UIImage coordinate system that SwiftUI uses for display.
        
        // First, convert normalized coordinates to CGImage pixel coordinates
        let cgX = x * cgImageSize.width
        let cgY = y * cgImageSize.height
        
        // Then apply orientation transformation to get UIImage coordinate space
        let (uiX, uiY): (CGFloat, CGFloat)
        
        switch orientation {
        case .up:
            // No transformation needed
            uiX = cgX
            uiY = cgY
        case .right: // 90° clockwise (orientation 3)
            // When rotated 90° CW: x' = height - y, y' = x
            uiX = cgImageSize.height - cgY
            uiY = cgX
        case .down: // 180°
            uiX = cgImageSize.width - cgX
            uiY = cgImageSize.height - cgY
        case .left: // 90° counter-clockwise
            uiX = cgY
            uiY = cgImageSize.width - cgX
        default:
            // For mirrored orientations, use base transformation
            uiX = cgX
            uiY = cgY
        }
        
        // Finally, scale from UIImage coordinate space to display size
        let displayX = (uiX / uiImageSize.width) * displaySize.width
        let displayY = (uiY / uiImageSize.height) * displaySize.height
        
        return (displayX, displayY)
    }
    
    // MediaPipe 33-landmark bone connections
    static func mediaPipeBones(dots: [CGPoint]) -> [Line] {
        guard dots.count >= 33 else { return [] }
        
        // MediaPipe Pose 33-landmark connections
        let connections: [(Int, Int)] = [
            // Face outline (landmarks 0-10)
            (0, 1), (1, 2), (2, 3), (3, 7),
            (0, 4), (4, 5), (5, 6), (6, 8),
            (9, 10),
            
            // Shoulders and arms
            (11, 12), // shoulder to shoulder
            (11, 13), (13, 15), // left arm
            (12, 14), (14, 16), // right arm
            
            // Hand details (if available)
            (15, 17), (17, 19), (19, 15), (15, 21), // left hand
            (16, 18), (18, 20), (20, 16), (16, 22), // right hand
            
            // Torso
            (11, 23), (12, 24), // shoulders to hips
            (23, 24), // hip to hip
            
            // Legs
            (23, 25), (25, 27), // left leg
            (24, 26), (26, 28), // right leg
            
            // Feet details
            (27, 29), (29, 31), (27, 31), // left foot
            (28, 30), (30, 32), (28, 32), // right foot
            
            // Additional body connections for stability
            (11, 24), (12, 23), // cross-body connections
        ]
        
        // Create lines from valid connections
        let bones: [Line] = connections.compactMap { connection in
            let fromIndex = connection.0
            let toIndex = connection.1
            
            // Ensure indices are within bounds
            guard fromIndex < dots.count && toIndex < dots.count else { return nil }
            
            return Line(from: dots[fromIndex], to: dots[toIndex])
        }
        
        return bones
    }
    
}
