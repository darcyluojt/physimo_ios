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
    var apple2DResult: BodyDetectionResult? = nil

    private let imageProcessor = ImageProcessor()

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
          let calculated = calculatedMetrics(from: result)
          
          
          await MainActor.run {
              self.metrics = calculated
              // Extract MediaPipe 2D landmarks for visualization
              self.poseLandmarks = result.mpPose?.landmarks2D
              // Store Apple 2D result for visualization
              self.apple2DResult = result.pose2D
          }
          
          processingResult = calculated.isEmpty ? "No metrics found." : "Calculated \(calculated.count) metrics."
          
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
        pose2D: BodyDetectionResult?,
        pose3D: BodyDetectionResult?,
        mpPose: MediaPipePoseResult?
      )
    ) -> [Metric] {
        var allMetrics: [Metric] = []
        
        if let apple3D = result.pose3D {
            allMetrics.append(contentsOf: apple3D.calculateMetrics(source: .HumanBodyPose3DObservation))
        }
        
        if let apple2D = result.pose2D {
            allMetrics.append(contentsOf: apple2D.calculateMetrics(source: .HumanBodyPoseObservation))
        }
        
        if let mpPose = result.mpPose {
            allMetrics.append(contentsOf: mpPose.toBodyDetectionResult3D().calculateMetrics(source: .MediaPipePoseWorldLandmarks))
            allMetrics.append(contentsOf: mpPose.toBodyDetectionResult2D().calculateMetrics(source: .MediaPipePoseLandmarks))
        }

        return allMetrics
    }

}

