import Foundation
import _PhotosUI_SwiftUI
import UIKit
import PhotosUI
import MediaPipeTasksVision
import Vision

@Observable
class UploadViewModel {
    var selectedImage: UIImage?
    var processingResult: String = ""
    var metrics: [Metric] = []
    var poseLandmarks: [NormalizedLandmark]? = nil
    var apple2DResult: DetectionResult2D? = nil

    private let imageProcessor = ImageProcessor()
    private let uploadStore: UploadStore

    init(uploadStore: UploadStore = .shared) {
        self.uploadStore = uploadStore
    }

    func handlePickedItem(_ item: PhotosPickerItem?) async {
        await processPicked(item)
    }

    private func processPicked(_ item: PhotosPickerItem?) async {
        resetState()
        guard let item = item,
              let image = await loadImage(from: item)
        else {
            processingResult = "Failed to load image."
            return
        }
        await MainActor.run {
            selectedImage = image
        }
        processingResult = "Processing image..."

        do {
             let result = try await imageProcessor.process(image: image)
          let uploadId = UUID()
          let calculated = calculatedMetrics(from: result, uploadId: uploadId)
          
          // Log success/failure analysis
          print("🎯 UploadViewModel Results:")
          print("  Metrics calculated: \(calculated.count)")
          print("  Has pose landmarks: \(result.mpPose?.landmarks2D != nil)")
          print("  Landmarks count: \(result.mpPose?.landmarks2D.count ?? 0)")
          print("  Has Apple 2D landmarks: \(result.pose2D != nil)")
          print("  Apple 2D joints count: \(result.pose2D?.allJoints().count ?? 0)")
          
          await MainActor.run {
              self.metrics = calculated
              // Extract MediaPipe 2D landmarks for visualization
              self.poseLandmarks = result.mpPose?.landmarks2D
              // Store Apple 2D result for visualization
              self.apple2DResult = result.pose2D
          }
          
          processingResult = calculated.isEmpty ? "No metrics found." : "Calculated \(calculated.count) metrics."
          let upload = StoredUpload(id: uploadId, image: image, metrics: calculated)
          uploadStore.save(upload)
          
          // Final success indicator
          let hasVisualOverlays = result.mpPose?.landmarks2D != nil && !result.mpPose!.landmarks2D.isEmpty
          print("✅ Processing SUCCESS - Visual overlays: \(hasVisualOverlays ? "YES" : "NO")")
          print(String(repeating: "=", count: 50))
          
        } catch {
          print("❌ Processing FAILED: \(error)")
          print(String(repeating: "=", count: 50))
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

