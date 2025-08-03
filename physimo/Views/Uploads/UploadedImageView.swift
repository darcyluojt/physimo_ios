import SwiftUI
import MediaPipeTasksVision

struct UploadedImageView: View {
    var image: UIImage?
    var landmarks: [NormalizedLandmark]?
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
                            
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: displayWidth, height: displayHeight)
                            
                            Canvas { context, size in
                                ImageAnalyser.drawOverlays(
                                    in: context,
                                    size: CGSize(width: displayWidth, height: displayHeight),
                                    for: uiImage,
                                    fromMP2D: landmarks)
                            }
                            .frame(width: displayWidth, height: displayHeight)
                        } else {
                            Text("Can't find image")
                        }
                    }
                    .frame(height: fullGeometry.size.height * 0.9)
                    
                    // Metrics section - scrollable below image
                    if !metrics.isEmpty {
                        LazyVStack {
                            ForEach(metrics, id: \.id) { metric in
                                HStack {
                                    Text("\(metric.source.displayName)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(metric.archetype.side.rawValue.capitalized)
                                    Text("\(metric.value, specifier: "%.1f")°")
                                    if let acc = metric.accuracy {
                                        Text("Accuracy: \(acc, specifier: "%.2f")")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                Divider()
                            }
                        }
                        .padding(.top, 20)
                    }
                }
            }
        }
    }
}
