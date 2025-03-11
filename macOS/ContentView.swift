import SwiftUI
import SwiftWebView

struct ContentView: View {
    @AppStorage("urls") var urls: [String] = []
    @AppStorage("columnsCount") var columnsCount: Double = 3
    @AppStorage("rowsCount") var rowsCount: Double = 2
    @AppStorage("zoom") var zoom: Double = 70
    @AppStorage("sideMenuVisibility") var sideMenuVisibility: NavigationSplitViewVisibility =
        .detailOnly

    var columns: [GridItem] {
        [GridItem](
            repeating: GridItem(.flexible(minimum: 10), spacing: 0),
            count: Int(columnsCount)
        )
    }

    func formatUrlString(_ url: String) -> String {
        return url.replacing(/^https?:\/\//, with: "").replacing(/\/$/, with: "")
    }

    func openNewWindow() {
        urls.append("")
    }

    func closeWindow(_ urlString: String) {
        urls.removeAll { $0 == urlString }
    }

    func closeAllWindows() {
        urls = []
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $sideMenuVisibility) {
            NoWindowsMessageView(urls: $urls)

            if !urls.isEmpty {
                List {
                    Section("Opened windows") {
                        ForEach(urls, id: \.self) { urlString in
                            HStack {
                                Text(urlString.isEmpty ? "Blank window" : urlString)
                                
                                Spacer()
                                
                                Button {
                                    closeWindow(urlString)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .opacity(0.7)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        } detail: {
            NoWindowsMessageView(urls: $urls)

            if !urls.isEmpty {
                GeometryReader { geometry in
                    LazyVGrid(columns: columns, spacing: 0) {
                        ForEach(Array(urls.indices), id: \.self) { index in
                            SwiftWebView(
                                urlString: Binding<String>(
                                    get: {
                                        guard index < urls.count else {
                                            return ""
                                        }
                                        return urls[index]
                                    },
                                    set: {
                                        guard index < urls.count else { return }
                                        urls[index] = $0
                                    }
                                ),
                                controls: .closable,
                                zoom: Binding<Double?>(
                                    get: { zoom },
                                    set: { if let newValue = $0 { zoom = newValue } }
                                )
                            )
                            .frame(height: max((geometry.size.height / rowsCount) - 6, 0))
                            .cornerRadius(10)
                            .padding(2)
                        }
                    }
                    .padding(2)
                }
            }
        }
        .toolbar {
            ToolbarAction_openNewWindow { openNewWindow() }
            ToolbarAction_columnsCount(columnsCount: $columnsCount)
            ToolbarAction_rowsCount(rowsCount: $rowsCount)
            ToolbarAction_zoom(zoom: $zoom)
            ToolbarAction_closeAllWindows { closeAllWindows() }
        }
        .onAppear {
            print("Loaded urls:", urls)
        }
    }
}

#Preview(traits: .fixedLayout(width: 1920, height: 1080)) {
    ContentView()
}
