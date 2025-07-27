import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            ImageAnalysisView()
                .tabItem {
                    Label("Image Analysis", systemImage: "photo")
                }

            StatusView()
                .tabItem {
                    Label("Status", systemImage: "waveform.path.ecg")
                }

            CameraView()
                .tabItem {
                    Label("Camera", systemImage: "camera")
                }
        }
    }
}

struct StatusView: View {
    var body: some View {
        Text("Status Placeholder")
    }
}

struct CameraView: View {
    var body: some View {
        Text("Camera Placeholder")
    }
}

#Preview {
    MainView()
}

