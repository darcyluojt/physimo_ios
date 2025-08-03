import Foundation
import SwiftUICore
import UIKit
import MediaPipeTasksVision

struct Line {
  let from: CGPoint
  let to: CGPoint
}

struct PoseOverlay {
  let dots: [CGPoint]
  let lines: [Line]
    let color: UIColor
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
        let originalSize = analyser.imageSize(for: image)
        let widthRatio = size.width / originalSize.width
        let heightRatio = size.height / originalSize.height
        let scale = min(heightRatio, widthRatio)
        let scaledSize = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)
        
        let overlays = analyser.poseOverlays(fromMP2D: landmarks, overlaySize: scaledSize)
        
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
    
    
    private func imageSize(for image: UIImage) -> CGSize {
        switch image.imageOrientation {
        case .up, .down, .left, .right:
            return image.size
        default:
            return CGSize(width: image.size.width * image.scale,
                          height: image.size.height * image.scale)
        }
    }
    
    
    func poseOverlays(
        fromMP2D: [NormalizedLandmark],
        overlaySize: CGSize,
) -> [PoseOverlay] {
        
        guard !fromMP2D.isEmpty else { return [] }
        let width = overlaySize.width
        let height = overlaySize.height
        
        // Convert normalized landmarks to screen coordinates
        let dots: [CGPoint] = fromMP2D.map { landmark in
            CGPoint(x: CGFloat(landmark.x) * width,
                   y: CGFloat(landmark.y) * height)
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
    
    
    
}
