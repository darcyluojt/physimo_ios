import SwiftUI
struct MenuBarView: View {
    @Binding var selectedTab: Tab
    
    var body: some View {
        HStack {
            menuButton(systemImage: "house", tab: .home)
            Spacer()
            menuButton(systemImage: "camera.fill", tab: .record)
            Spacer()
            menuButton(systemImage: "waveform.path.ecg", tab: .metrics)
            Spacer()
            menuButton(systemImage: "person.crop.circle", tab: .profile)
        }
        .padding(.horizontal, 30)
        .padding(.top, 10)
        .padding(.bottom, 20)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .shadow(radius: 5)
    }
    
    @ViewBuilder
    func menuButton(systemImage: String, tab: Tab) -> some View {
        Button(action: {
            self.selectedTab = tab
        }) {
            Image(systemName: systemImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 25, height: 25)
                .foregroundColor(selectedTab == tab ? .blue : .gray)
        }
    }
}



