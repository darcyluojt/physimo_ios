import SwiftUI

struct MainView: View {
    @State private var showUploadSheet = false
    @State private var showCamera = false
    @State private var selectedTab: Tab = .home
    var body: some View {
        
        NavigationView {
            VStack {
                Spacer()
                // Upload Video Button
                HStack(spacing: 40) {
                    Button(action: { showUploadSheet = true }) {
                        VStack(spacing: 16) {
                            Image(systemName: "square.and.arrow.up")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                            Text("Upload")
                                .font(.headline)
                        }
                        .frame(minWidth: 100, maxWidth: .infinity) 
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                    }
                    .sheet(isPresented: $showUploadSheet) {
                        AddUploadView()
                    }
                    
                    // Live Camera Button
                    Button(action: { showCamera = true }) {
                        VStack(spacing: 16) {
                            Image(systemName: "video.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                            Text("Live")
                                .font(.headline)
                        }
                        .frame(minWidth: 100, maxWidth: .infinity)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                    }
                    .fullScreenCover(isPresented: $showCamera) {
                        LiveCameraView()
                    }
                }
                Spacer()
                MenuBarView(selectedTab: $selectedTab)
                    .onChange(of: selectedTab) { _, newTab in
                        if newTab == .home {
                            showUploadSheet = false
                            showCamera = false
                        }
                    }
                    .padding()
                    .navigationTitle("PhysiMo")
            }
        }
    }
    
    struct LiveCameraView: View {
        @Environment(\.presentationMode) private var presentationMode
        
        var body: some View {
            VStack {
                Text("Live Camera View")
                    .font(.title)
                    .padding()
                Button("Dismiss") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
