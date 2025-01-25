import SwiftUI

struct NoWindowsMessageView: View {
    @Binding var urls: [String]
    
    var body: some View {
        if (urls.isEmpty) {
            ContentUnavailableView {
                Text("No windows opened")
            } description: {
                Text("Open first window to start browsing")
            } actions: {
                Button {
                    urls.append("")
                } label: {
                    Label("New window", systemImage: "plus")
                        .labelStyle(.titleAndIcon)
                }
            }
        }
    }
}

#Preview {
    @Previewable
    @State var urls: [String] = []
    
    NoWindowsMessageView(urls: $urls)
}
