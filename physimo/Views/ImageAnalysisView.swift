import SwiftUI
import PhotosUI

struct ImageAnalysisView: View {
    @State private var images: [UIImage] = []
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        NavigationView {
            List {
                ForEach(images.indices, id: \.self) { index in
                    NavigationLink(destination: ImageDetailView(image: images[index])) {
                        Image(uiImage: images[index])
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                    }
                }
                Button(action: { showImagePicker = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Image")
                    }
                }
            }
            .navigationTitle("Image Analysis")
        }
        .photosPicker(isPresented: $showImagePicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) {
            if let item = selectedItem {
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        images.append(uiImage)
                    }
                }
            }
        }
    }
}

struct ImageDetailView: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .navigationTitle("Detail")
    }
}
