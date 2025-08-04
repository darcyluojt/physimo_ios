import SwiftUI
import PhotosUI

struct AddUploadView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var viewModel = UploadViewModel()
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var showPicker = false
    @State private var navigate = false
    
    var body: some View {
        Color.clear
            .onAppear {
                showPicker = true
            }
            .sheet(isPresented: $showPicker) {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Text("Upload an image from your photo library")
                }
                .onChange(of: selectedItem) {
                    guard let picked = selectedItem else { return }
                    showPicker = false
                    Task {
                        await viewModel.handlePickedItem(picked)
                        navigate = true
                    }
                }
            }
            .navigationDestination(isPresented: $navigate) {
                UploadedImageView(
                    image: viewModel.selectedImage,
                    landmarks: viewModel.poseLandmarks,
                    apple2DResult: viewModel.apple2DResult,
                    metrics: viewModel.metrics)
            }
    }
}
