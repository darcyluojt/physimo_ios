import Foundation
import UIKit
import PhotosUI

class UUploadViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var processingResult: String = ""
    @Published var metrics: [Metric] = []
    
    private let imageProcessor = ImageProcessor()
    
    func handlePickedItem(_ item: PhtosPickerItem? ) {
        Task { await processPicked(item) }
    }
}

