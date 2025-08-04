import SwiftUI
import PhotosUI

struct MainView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ImageAnalysisView()
            }
            .tabItem {
                Label("Pose Analysis", systemImage: "figure.walk")
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

