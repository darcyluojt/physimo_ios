import SwiftUI
import PhotosUI

struct AddUploadView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var processingResult: String? = nil
    @State private var metrics: [Metric] = []
    @State private var selectedTab: Tab = .record
    
    private let archetypes = Archetype.all

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
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(metrics) { metric in
                            HStack {
                                Text(metric.archetype.slug
                                    .replacingOccurrences(of: "_", with: " ")
                                    .capitalized)
                                    .bold()
                                Text("\(metric.value, specifier: "%.1f")°")
                                Spacer()
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
            
            // 2. Run the Vision 3D-pose detector
            if let detection = await ImageProcessor.process(image: image) {
                // 3. Generate an upload ID
                let uploadId = UUID()
                
                // 4. Calculate knee‐angle metrics
                let newMetrics = MetricsCalculator.calculateKneeAngles(
                    from: detection,
                    uploadId: uploadId,
                    archetypes: archetypes
                )
                
                metrics = newMetrics
                
                // 5. Update status
                if newMetrics.isEmpty {
                    processingResult = "No full knee joints detected."
                } else {
                    processingResult = "Calculated \(newMetrics.count) knee‐angle metric(s)."
                }
            } else {
                processingResult = "No pose detected."
            }
        }
    }
