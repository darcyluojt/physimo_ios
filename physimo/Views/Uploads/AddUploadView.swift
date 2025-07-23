import SwiftUI
import PhotosUI

struct AddUploadView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = UploadViewModel()
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedTab: Tab = .record
    
    var body: some View {
        VStack(spacing: 16) {
            PhotosPicker(
                selection: $selectedItem,
                matching:   .images,
                photoLibrary: .shared()
            ) {
                Text("Select Image")
            }

            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(8)
            }

            Text(viewModel.processingResult)
                .font(.caption)
                .foregroundColor(.blue)

            if !viewModel.metrics.isEmpty {
                List(viewModel.metrics) { metric in
                    HStack {
                        Text("\(metric.source.displayName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                        Text(metric.archetype.side.rawValue
                                .capitalized)
                        Text("\(metric.value, specifier: "%.1f")°")
                        if let acc = metric.accuracy {
                            Text("Accuracy: \(acc, specifier: "%.2f")")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(height: 350)
            }

            Spacer()
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Dismiss") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .onChange(of: selectedItem) { newItem in
            Task { await viewModel.handlePickedItem(newItem) }
        }


    }
}
struct AddUploadView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AddUploadView()
        }
    }
}
