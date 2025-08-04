import SwiftUI
import PhotosUI

struct ImageAnalysisView: View {
    @State private var images: [UIImage] = []
    @State private var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var viewModel = UploadViewModel()

    var body: some View {
            NavigationView {
                List {
                ForEach(images.indices, id: \.self) { index in
                        NavigationLink(destination: ImageDetailsView(image: images[index])) {
                            Image(uiImage: images[index])
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                        }
                    }

                }
                .navigationTitle("Image Analysis")
            }
        }
    }
