import SwiftUI
import MediaPipeTasksVision
import Vision

struct ImageDetailsView: View {
    var image: UIImage?
    var landmarks: [NormalizedLandmark]?
    var apple2DResult: DetectionResult2D?
    var metrics: [Metric] = []
    var body: some View {
        GeometryReader { fullGeometry in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Image section - 90% of screen height
                    ZStack {
                        if let uiImage = image {
                            // Calculate the actual display size of the image
                            let imageAspectRatio = uiImage.size.width / uiImage.size.height
                            let containerWidth = fullGeometry.size.width
                            let containerHeight = fullGeometry.size.height * 0.9
                            
                            // Calculate actual image display dimensions
                            let displayHeight = min(containerHeight, containerWidth / imageAspectRatio)
                            let displayWidth = min(containerWidth, displayHeight * imageAspectRatio)
                            
                            let _ = logImageViewDebug(
                                image: uiImage,
                                aspectRatio: imageAspectRatio,
                                container: CGSize(width: containerWidth, height: containerHeight),
                                displaySize: CGSize(width: displayWidth, height: displayHeight)
                            )
                            
                            ZStack {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                
                                Canvas { context, size in
                                    // Draw MediaPipe overlays in red
                                    ImageAnalyser.drawOverlays(
                                        in: context,
                                        size: size,
                                        for: uiImage,
                                        fromMP2D: landmarks)
                                    
                                    // Draw Apple 2D overlays in blue
                                    ImageAnalyser.drawApple2DOverlays(
                                        in: context,
                                        size: size,
                                        for: uiImage,
                                        fromApple2D: apple2DResult)
                                }
                            }
                            .frame(width: displayWidth, height: displayHeight)
                        } else {
                            Text("Can't find image")
                        }
                    }
                    .frame(height: fullGeometry.size.height * 0.9)
                    
                    // Metrics section - scrollable below image
                    if !metrics.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Joint Angle Measurements")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            // Create metrics grid
                            MetricsGridView(metrics: metrics)
                                .padding(.horizontal)
                        }
                        .padding(.top, 20)
                    }
                }
            }
        }
    }
    
    private func logImageViewDebug(image: UIImage, aspectRatio: CGFloat, container: CGSize, displaySize: CGSize) -> Void {
        print("📱 ImageDetailsView Debug:")
        print("  UIImage.size: \(image.size)")
        print("  UIImage.orientation: \(image.imageOrientation.rawValue)")
        print("  Calculated aspect ratio: \(aspectRatio)")
        print("  Container: \(container.width) x \(container.height)")
        print("  Final display size: \(displaySize.width) x \(displaySize.height)")
    }
}

struct MetricsGridView: View {
    let metrics: [Metric]
    
    var body: some View {
        let sources = Array(Set(metrics.map { $0.source })).sorted { $0.displayName < $1.displayName }
        
        VStack(spacing: 8) {
            // Header row
            HStack {
                Text("Source")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Left")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                
                Text("Right")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // Data rows
            ForEach(sources, id: \.self) { source in
                HStack {
                    // Source name
                    Text(source.displayName)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Left value
                    if let leftMetric = metrics.first(where: { $0.source == source && $0.archetype.side == .left }) {
                        VStack {
                            Text("\(leftMetric.value, specifier: "%.1f")°")
                                .font(.body)
                            if let accuracy = leftMetric.accuracy {
                                Text("(\(accuracy * 100, specifier: "%.0f")%)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Text("—")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                    
                    // Right value
                    if let rightMetric = metrics.first(where: { $0.source == source && $0.archetype.side == .right }) {
                        VStack {
                            Text("\(rightMetric.value, specifier: "%.1f")°")
                                .font(.body)
                            if let accuracy = rightMetric.accuracy {
                                Text("(\(accuracy * 100, specifier: "%.0f")%)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Text("—")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 12)
                .background(Color.clear)
                
                if source != sources.last {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
