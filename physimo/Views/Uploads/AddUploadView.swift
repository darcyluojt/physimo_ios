import SwiftUI
import PhotosUI

struct AddUploadView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = UploadViewModel()
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var processingResult: String? = nil
    @State private var metrics: [Metric] = []
    @State private var selectedTab: Tab = .record
    
    private let archetypes = Archetype.all
    private var groupedMetricsBySource: [(source: Metric.Source, metrics: [Metric])] {
        let grouped: [Metric.Source: [Metric]] = Dictionary(grouping: metrics, by: { $0.source })
        let sortedKeys = grouped.keys.sorted { $0.displayName < $1.displayName }
        
        return sortedKeys.compactMap { key in
            if let values = grouped[key] {
                return (source: key, metrics: values)
            }
            return nil
        }
    }


    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Show selected image
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                }
                
                // Status message
                if let result = processingResult {
                    Text(result)
                        .foregroundColor(.blue)
                        .padding(.top)
                }
                
                // 3. Display computed metrics
                if !metrics.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(groupedMetricsBySource, id: \.source) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(group.source.displayName)
                                    .font(.headline)
                                    .foregroundColor(.blue)

                                ForEach(group.metrics) { metric in
                                    HStack {
                                        Text(metric.archetype.slug
                                            .replacingOccurrences(of: "-", with: " ")
                                            .capitalized)
                                        .bold()

                                        Text("\(metric.value, specifier: "%.1f")°")

                                        if let accuracy = metric.accuracy {
                                            Text("Accuracy: \(accuracy, specifier: "%.2f")")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }

                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }

                
                // PhotosPicker
                PhotosPicker("Select Image",
                             selection: $selectedItem,
                             matching: .images,
                             photoLibrary: .shared()
                )
                .onChange(of: selectedItem) {
                    Task {
                        await handlePickedItem(selectedItem)
                    }
                }
                
                Spacer()
                MenuBarView(selectedTab: $selectedTab)
                    .onChange(of: selectedTab) { tab in
                        if tab == .home {
                            presentationMode.wrappedValue.dismiss()
                        }
                        
                    }                            }
            .padding()
            .navigationTitle("New Upload")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Image & Metric Processing
    func handlePickedItem(_ item: PhotosPickerItem?) async {
        // Reset state
        selectedImage = nil
        processingResult = ""
        metrics = []
        
        // 1. Load UIImage from picker item
        guard
            let item,
            let data = try? await item.loadTransferable(type: Data.self),
            let image = UIImage(data: data)
        else {
            processingResult = "Failed to load image."
            return
        }
        
        selectedImage = image
        processingResult = "Processing..."
        let processor = ImageProcessor()
        
        Task {
            do {
                // 1️⃣ Call process() and handle its throwable nature
                let (maybe2D, maybe3D, maybemp) = try await processor.process(image: image)
                let(maybe_mp_2d, mapbe_mp_3d) = maybemp!
                let uploadId = UUID()
                var newMetrics: [Metric] = []
//                Calculate metrics from apple 3d poses coordiantes
                if let pose3D = maybe3D {
                    let metrics3D = MetricsCalculator.calculateKneeAngles(
                        from: pose3D,
                        uploadId: uploadId,
                        archetypes: archetypes,
                        source: .HumanBodyPose3DObservation
                    )
                    newMetrics.append(contentsOf: metrics3D)
                } else {
                    print("No 3D pose detected")
                }
//                Calculate metrics from apple 2d poses coordiantes
                if let pose2D = maybe2D {
                    let metrics2D = MetricsCalculator.calculateKneeAngles2D(
                        from: pose2D,
                        uploadId: uploadId,
                        archetypes: archetypes,
                        source: .HumanBodyPoseObservation
                    )
                    newMetrics.append(contentsOf: metrics2D)
                } else {
                    print("No 2D pose detected")
                }
            
                
                
                // 6️⃣ Store/update your metrics
                metrics = newMetrics
                if newMetrics.isEmpty {
                    processingResult = "No full knee joints detected."
                } else {
                    processingResult = "Calculated \(newMetrics.count) knee‐angle metric(s)."
                }
            } catch {
                    print(error)
                    processingResult = "image processing failed."
                }
            }
        }
}
