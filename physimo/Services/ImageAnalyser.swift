import Foundation
import SwiftUICore
import UIKit
import MediaPipeTasksVision
import Vision

struct Line {
  let from: CGPoint
  let to: CGPoint
}

struct PoseOverlay {
  let dots: [CGPoint]
  let lines: [Line]
    let color: UIColor
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
    var poseOverlays: [PoseOverlay] = []
    var imageSize: CGSize = CGSizeZero
    var imageContentMode: UIView.ContentMode = .scaleAspectFit
    let r = 2.0
    
    static func drawOverlays(
        in context: GraphicsContext,
        size: CGSize,
        for image: UIImage,
        fromMP2D: [NormalizedLandmark]? = nil
    ) {
        guard let landmarks = fromMP2D, !landmarks.isEmpty else { return }
        let analyser = ImageAnalyser()
        
        // Use shared display metrics calculation
        let metrics = ImageDisplayMetrics(image: image, canvasSize: size)
        metrics.printDebugInfo(prefix: "🔍 MediaPipe")
        print("  First landmark: (\(landmarks[0].x), \(landmarks[0].y))")
        
        let overlays = analyser.poseOverlays(
            fromMP2D: landmarks, 
            overlaySize: metrics.scaledImageSize,
            offset: metrics.offset,
            image: image
        )
        
        // Draw each overlay using SwiftUI's GraphicsContext
        for overlay in overlays {
            // Draw dots
            for dot in overlay.dots {
                let rect = CGRect(x: dot.x - 2, y: dot.y - 2, width: 4, height: 4)
                context.fill(Path(ellipseIn: rect), with: .color(Color(overlay.color)))
            }
            
            // Draw lines
            for line in overlay.lines {
                var path = Path()
                path.move(to: line.from)
                path.addLine(to: line.to)
                context.stroke(path, with: .color(Color(overlay.color)), lineWidth: 2)
            }
        }
    }
    
    static func drawApple2DOverlays(
        in context: GraphicsContext,
        size: CGSize,
        for image: UIImage,
        fromApple2D: DetectionResult2D? = nil
    ) {
        guard let apple2DResult = fromApple2D else { return }
        let landmarks = apple2DResult.allJoints()
        guard !landmarks.isEmpty else { return }
        
        let analyser = ImageAnalyser()
        
        // Use shared display metrics calculation
        let metrics = ImageDisplayMetrics(image: image, canvasSize: size)
        metrics.printDebugInfo(prefix: "🍎 Apple2D")
        print("  Apple 2D joints available: \(landmarks.keys.map { $0.rawValue }.joined(separator: ", "))")
        
        // Convert Apple 2D landmarks to dots (just dots for now, no lines)
        let dots = analyser.apple2DDots(
            fromApple2D: apple2DResult,
            metrics: metrics
        )
        
        // Draw Apple 2D dots in blue
        for dot in dots {
            let rect = CGRect(x: dot.x - 3, y: dot.y - 3, width: 6, height: 6)
            context.fill(Path(ellipseIn: rect), with: .color(.blue))
        }
        
        print("  Apple 2D dots drawn: \(dots.count)")
    }
    
    
    private func imageSize(for image: UIImage) -> CGSize {
        // Since SwiftUI displays the image using UIImage.size (orientation-corrected),
        // we should use UIImage.size for consistent scaling calculations
        return image.size
    }
    
    
    func poseOverlays(
        fromMP2D: [NormalizedLandmark],
        overlaySize: CGSize,
        offset: CGPoint = .zero,
        image: UIImage
) -> [PoseOverlay] {
        
        guard !fromMP2D.isEmpty else { return [] }
        let width = overlaySize.width
        let height = overlaySize.height
        
        print("🎯 PoseOverlays Debug:")
        print("  Overlay size: \(overlaySize)")
        print("  Offset: \(offset)")
        print("  Image orientation: \(image.imageOrientation.rawValue)")
        
        // MediaPipe processes raw CGImage data without orientation correction
        // We need to transform landmarks based on image orientation to match SwiftUI display
        
        let uiImageSize = image.size  // SwiftUI display dimensions
        let cgImageSize = image.cgImage.map { CGSize(width: $0.width, height: $0.height) } ?? image.size
        
        let dots: [CGPoint] = fromMP2D.map { landmark in
            let x = CGFloat(landmark.x)
            let y = CGFloat(landmark.y)
            
            // Transform coordinates based on image orientation
            let (transformedX, transformedY) = transformCoordinates(
                x: x, y: y, 
                orientation: image.imageOrientation,
                cgImageSize: cgImageSize,
                uiImageSize: uiImageSize,
                displaySize: overlaySize
            )
            
            // Apply offset for centering
            return CGPoint(
                x: transformedX + offset.x,
                y: transformedY + offset.y
            )
        }
        
        print("  Sample transformed points:")
        for i in 0..<min(3, dots.count) {
            let original = fromMP2D[i]
            print("    [\(i)] Original: (\(original.x), \(original.y)) -> Final: (\(dots[i].x), \(dots[i].y))")
        }
        
        // MediaPipe pose connections (based on the 33 landmark model)
        let connections: [(Int, Int)] = [
            
            // Body connections
            (11, 12), (11, 13), (11, 23), (12, 14), (12, 24),
            (13, 15), (14, 16), (15, 17), (15, 19), (15, 21),
            (16, 18), (16, 20), (16, 22), (17, 19), (18, 20),
            // Hip connections
            (23, 24), (23, 25), (24, 26),
            // Leg connections
            (25, 27), (26, 28), (27, 29), (27, 31), (28, 30),
            (28, 32), (29, 31), (30, 32)
        ]
        
        // Create lines from valid connections
        let lines: [Line] = connections.compactMap { connection in
            guard connection.0 < dots.count && connection.1 < dots.count else { return nil }
            return Line(from: dots[connection.0], to: dots[connection.1])
        }
        
        let overlay = PoseOverlay(dots: dots, lines: lines, color: .red)
        return [overlay]
    }
    
    private func transformCoordinates(
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
    
    func apple2DDots(
        fromApple2D: DetectionResult2D,
        metrics: ImageDisplayMetrics
    ) -> [CGPoint] {
        print("🎯 Apple2D Dots Debug:")
        print("  Overlay size: \(metrics.scaledImageSize)")
        print("  Offset: \(metrics.offset)")
        print("  Image orientation: \(metrics.image.imageOrientation.rawValue)")
        
        // Convert Apple 2D landmarks to screen coordinates
        // First, let's test if Apple coordinates need transformation like MediaPipe
        var dots: [CGPoint] = []
        
        let landmarks = fromApple2D.allJoints()
        for (jointName, recognizedPoint) in landmarks {
            let landmark = recognizedPoint.location.cgPoint
            let x = landmark.x
            let y = landmark.y
            
            // Apple Vision uses bottom-left origin (0,0), but SwiftUI uses top-left origin
            // Need to flip Y-coordinate: newY = 1.0 - oldY
            let flippedY = 1.0 - y
            
            // Scale to display size
            let displayX = x * metrics.scaledImageSize.width + metrics.offset.x
            let displayY = flippedY * metrics.scaledImageSize.height + metrics.offset.y
            
            dots.append(CGPoint(x: displayX, y: displayY))
            
            print("    \(jointName.rawValue): (\(x), \(y)) -> (\(displayX), \(displayY))")
        }
        
        return dots
    }
    
}
