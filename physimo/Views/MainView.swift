import SwiftUI
import PhotosUI

struct MainView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ImageAnalysisView()
            }
            .tabItem {
                Label("Image Analysis", systemImage: "photo")
            }

            NavigationStack {
                StatusView()
            }
            .tabItem {
                Label("Status", systemImage: "waveform.path.ecg")
            }

            NavigationStack {
                CameraView()
            }
            .tabItem {
                Label("Camera", systemImage: "camera")
            }

            NavigationStack {
                AddUploadView()
            }
            .tabItem {
                Label("Upload", systemImage: "square.and.arrow.up")
            }
        }
    }
}

struct StatusView: View {
    var body: some View {
      Text("Status View")
    }
}

struct CameraView: View {
    var body: some View {
      Text("Camera View")
    }
}

struct ImageAnalysisView: View {
    var body: some View {
        Text("All iamge")
    }
}

