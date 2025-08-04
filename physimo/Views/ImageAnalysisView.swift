import SwiftUI
import PhotosUI
import MediaPipeTasksVision

struct ProcessedImage: Identifiable {
    let id = UUID()
    let image: UIImage
    let landmarks: [NormalizedLandmark]?
    let apple2DResult: BodyDetectionResult?
    let metrics: [Metric]
    let processingStatus: String
    let captureDate: Date?

    var displayName: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short

        if let captureDate = captureDate {
            return "Photo \(formatter.string(from: captureDate))"
        } else {
            return "Photo \(formatter.string(from: Date()))"
        }
    }

    var formattedCaptureDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        if let captureDate = captureDate {
            return formatter.string(from: captureDate)
        } else {
            return "Unknown date"
        }
    }

    var metricsBreakdown: String {
        let sources = Set(metrics.map { $0.source.displayName })
        if sources.isEmpty {
            return "No metrics calculated"
        } else {
            return "\(metrics.count) metrics from \(sources.count) source\(sources.count == 1 ? "" : "s")"
        }
    }
}

struct ImageAnalysisView: View {
    @State private var processedImages: [ProcessedImage] = []
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var viewModel = UploadViewModel()
    @State private var isProcessing = false

    var body: some View {
        NavigationView {
            VStack {
                // Photo picker button
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack {
                        Image(systemName: "photo.badge.plus")
                        Text("Add Image for Analysis")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
                .disabled(isProcessing)

                // Processing status
                if isProcessing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Processing image...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }

                // List of processed images
                if processedImages.isEmpty && !isProcessing {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "photo.artframe")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No images analyzed yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Add an image to see pose analysis with MediaPipe skeleton rendering")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(processedImages) { processedImage in
                            NavigationLink(
                                destination: ImageDetailsView(
                                    image: processedImage.image,
                                    landmarks: processedImage.landmarks,
                                    apple2DResult: processedImage.apple2DResult,
                                    metrics: processedImage.metrics
                                )
                            ) {
                                HStack {
                                    // Thumbnail
                                    Image(uiImage: processedImage.image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipped()
                                        .cornerRadius(8)

                                    VStack(alignment: .leading, spacing: 4) {git

                                        Text(processedImage.formattedCaptureDate)
                                            .font(.headline)

                                        Text(processedImage.metricsBreakdown)
                                            .font(.caption)
                                            .foregroundColor(.blue)

                                        // Show landmark counts
                                        HStack(spacing: 12) {
                                            if let landmarks = processedImage.landmarks {
                                                HStack(spacing: 4) {
                                                    Circle()
                                                        .fill(Color.red)
                                                        .frame(width: 8, height: 8)
                                                    Text("MediaPipe: \(landmarks.count)")
                                                        .font(.caption2)
                                                }
                                            }

                                            if let apple2D = processedImage.apple2DResult {
                                                HStack(spacing: 4) {
                                                    Circle()
                                                        .fill(Color.blue)
                                                        .frame(width: 8, height: 8)
                                                    Text("Apple: \(apple2D.landmarks.count)")
                                                        .font(.caption2)
                                                }
                                            }
                                        }

                                        // Show specific metrics if available
                                        if !processedImage.metrics.isEmpty {
                                            HStack(spacing: 8) {
                                                ForEach(Array(Set(processedImage.metrics.map { $0.configuration.side })), id: \.self) { side in
                                                    if let metric = processedImage.metrics.first(where: { $0.configuration.side == side }) {
                                                        VStack(alignment: .leading, spacing: 2) {
                                                            Text("\(side.rawValue.capitalized) Knee")
                                                                .font(.caption2)
                                                                .foregroundColor(.secondary)
                                                            Text("\(metric.value, specifier: "%.1f")°")
                                                                .font(.caption)
                                                                .fontWeight(.medium)
                                                                .foregroundColor(metric.configuration.status == .healthy ? .green : .orange)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteImages)
                    }
                }
            }
            .navigationTitle("Image Analysis")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !processedImages.isEmpty {
                        EditButton()
                    }
                }
            }
        }
        .onChange(of: selectedPhotoItem) { oldItem, newItem in
            if let newItem = newItem {
                processImage(from: newItem)
            }
        }
    }

    private func processImage(from item: PhotosPickerItem) {
        isProcessing = true

        Task {
            // Extract photo capture date first
            let captureDate = await extractCaptureDate(from: item)

            // Use the existing UploadViewModel processing logic
            await viewModel.handlePickedItem(item)

            await MainActor.run {
                if let processedImage = viewModel.selectedImage {
                    let newProcessedImage = ProcessedImage(
                        image: processedImage,
                        landmarks: viewModel.poseLandmarks,
                        apple2DResult: viewModel.apple2DResult,
                        metrics: viewModel.metrics,
                        processingStatus: viewModel.processingResult,
                        captureDate: captureDate
                    )

                    processedImages.insert(newProcessedImage, at: 0) // Add to top
                }

                isProcessing = false
                selectedPhotoItem = nil // Reset picker
            }
        }
    }

    private func extractCaptureDate(from item: PhotosPickerItem) async -> Date? {
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
               let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] {

                // Try EXIF data first
                if let exifData = properties[kCGImagePropertyExifDictionary as String] as? [String: Any],
                   let dateTimeOriginal = exifData[kCGImagePropertyExifDateTimeOriginal as String] as? String {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
                    if let date = formatter.date(from: dateTimeOriginal) {
                        return date
                    }
                }

                // Try TIFF data as fallback
                if let tiffData = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any],
                   let dateTime = tiffData[kCGImagePropertyTIFFDateTime as String] as? String {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
                    if let date = formatter.date(from: dateTime) {
                        return date
                    }
                }
            }
        } catch {
            print("Failed to extract capture date: \(error)")
        }

        return nil
    }

    private func deleteImages(offsets: IndexSet) {
        processedImages.remove(atOffsets: offsets)
    }
}
