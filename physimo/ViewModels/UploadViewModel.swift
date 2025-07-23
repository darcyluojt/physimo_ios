import Foundation
import _PhotosUI_SwiftUI
import UIKit
import PhotosUI

class UploadViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var processingResult: String = ""
    @Published var metrics: [Metric] = []

    private let imageProcessor = ImageProcessor()
    private let uploadStore: UploadStore

    init(uploadStore: UploadStore = .shared) {
        self.uploadStore = uploadStore
    }

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

        do {
             let result = try await imageProcessor.process(image: image)
          let uploadId = UUID()
          let calculated = calculatedMetrics(from: result, uploadId: uploadId)
          self.metrics = calculated
          processingResult = calculated.isEmpty ? "No metrics found." : "Calculated \(calculated.count) metrics."
          let upload = StoredUpload(id: uploadId, image: image, metrics: calculated)
          uploadStore.save(upload)
        } catch {
          processingResult = "Failed to process image."
        }
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

    private func calculatedMetrics(
      from result: (
        pose2D: DetectionResult2D?,
        pose3D: DetectionResult?,
        mpPose: MediaPipePoseResult?
      ),
      uploadId: UUID
    ) -> [Metric] {
        var allMetrics: [Metric] = []
        if let apple3D = result.pose3D {
          let apple3DMetrics = MetricsCalculator.calculateKneeAngles(
            fromApple3D: apple3D,
            uploadId: uploadId,
            archetypes: Archetype.all,
            source: .HumanBodyPose3DObservation
          )
          allMetrics.append(contentsOf: apple3DMetrics)
        }
        if let mp3D = result.mpPose?.landmarks3D {
            let jointVectors = mp3D.map { $0.simdVector }
            let confidenceList = mp3D.map { Double(truncating: $0.visibility ?? 0) }
            let mp3dMetrics = MetricsCalculator.calculateKneeAngles(
            fromMP3D: jointVectors,
            confidenceList: confidenceList,
            uploadId: uploadId,
            archetypes: Archetype.all,
            source: .MediaPipePoseWorldLandmarks
            )
          allMetrics.append(contentsOf: mp3dMetrics)
        }
        if let apple2D = result.pose2D {
          let apple2DMetrics = MetricsCalculator.CalculateKneeAngles2D(
            fromApple2D: apple2D,
            uploadId: uploadId,
            archetypes: Archetype.all,
            source: .HumanBodyPoseObservation
          )
          allMetrics.append(contentsOf: apple2DMetrics)
        }
        if let mp2D = result.mpPose?.landmarks2D {
            let jointPoints = mp2D.map { $0.cgPoint }
            let confidenceList = mp2D.map { Double(truncating: $0.visibility ?? 0) }
          let mp2dMetrics = MetricsCalculator.CalculateKneeAngles2D(
            fromMP2D: jointPoints,
            confidenceList: confidenceList,
            uploadId: uploadId,
            archetypes: Archetype.all,
            source: .MediaPipePoseLandmarks
          )
          allMetrics.append(contentsOf: mp2dMetrics)
        }

        return allMetrics
    }

}

