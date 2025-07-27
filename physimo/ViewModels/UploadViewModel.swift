import Foundation
import _PhotosUI_SwiftUI
import UIKit
import PhotosUI

class UploadViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var processingResult: String = ""
    @Published var metrics: [JointMetric] = []

    private let imageProcessor = ImageProcessorModel()


    func handlePickedItem(_ item: PhotosPickerItem?) {
        Task { await processPicked(item) }
    }

    private func processPicked(_ item: PhotosPickerItem?) async {
        resetState()
        guard let item = item,
              let image = await loadImage(from: item)
        else {
            processingResult = "Failed to load image."
            return
        }
        selectedImage = image
        processingResult = "Processing image..."

        let result = try await imageProcessor.process(image: image)
        self.metrics  = calculatedMetrics(from: result)
        processingResult = self.metrics.count == 0 ? "No metrics found." : "Calculated \(self.metrics.count) metrics."
    }

    private func resetState() {
        selectedImage = nil
        processingResult = ""
        metrics = []
    }

    private func loadImage(from item: PhotosPickerItem) async -> UIImage? {
      guard let data = try? await item.loadTransferable(type: Data.self),
            let image = UIImage(data: data) else {
          return nil
        }
        return image
    }

    private func calculatedMetrics(from result: [String: BodyDetectionResult]) -> [JointMetric] {
        var allMetrics: [JointMetric] = []

        for (modelName, detectionResult) in result {
            for config in JointConfiguration.all {
                let metric = JointMetric(from: config, modelName: modelName, detectionResult: detectionResult)
                allMetrics.append(metric)
            }
        }

        return allMetrics
    }

}

