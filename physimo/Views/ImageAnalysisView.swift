import SwiftUI
import PhotosUI

struct ProcessedImage: Identifiable {
    let id = UUID()
    let image: UIImage
    let landmarks: [NormalizedLandmark]?
    let apple2DResult: BodyDetectionResult?
    let metrics: [Metric]
    let processingStatus: String

    var displayName: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "Image \(formatter.string(from: Date()))"
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

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(processedImage.displayName)
                                            .font(.headline)

                                        Text(processedImage.processingStatus)
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        if !processedImage.metrics.isEmpty {
                                            Text("\(processedImage.metrics.count) metrics calculated")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }

                                        // Show landmark counts
                                        HStack(spacing: 12) {
                                            if let landmarks = processedImage.landmarks {
                                                HStack(spacing: 4) {
                                                    Circle()
                                                        .fill(Color.red)
                                                        .frame(width: 8, height: 8)
                                                    Text("MP: \(landmarks.count)")
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
            // Use the existing UploadViewModel processing logic
            await viewModel.handlePickedItem(item)

            await MainActor.run {
                if let processedImage = viewModel.selectedImage {
                    let newProcessedImage = ProcessedImage(
                        image: processedImage,
                        landmarks: viewModel.poseLandmarks,
                        apple2DResult: viewModel.apple2DResult,
                        metrics: viewModel.metrics,
                        processingStatus: viewModel.processingResult
                    )

                    processedImages.insert(newProcessedImage, at: 0) // Add to top
                }

                isProcessing = false
                selectedPhotoItem = nil // Reset picker
            }
        }
    }

    private func deleteImages(offsets: IndexSet) {
        processedImages.remove(atOffsets: offsets)
    }
}
