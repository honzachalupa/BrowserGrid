import SwiftUI
@preconcurrency import WebKit

extension Notification.Name {
    static let reloadAllWindows = Notification.Name("reloadAllWindows")
}

struct WebView: NSViewRepresentable {
    var url: URL
    var zoom: Double
    @Binding var webView: WKWebView
    
    class Coordinator: NSObject {
        var parent: WebView
        let navigationDelegate: NavigationDelegate
        
        init(_ parent: WebView) {
            self.parent = parent
            self.navigationDelegate = NavigationDelegate()
        }
        
        func configureWebView(_ webView: WKWebView) {
            DispatchQueue.main.async {
                webView.allowsBackForwardNavigationGestures = true
                webView.navigationDelegate = self.navigationDelegate
                
                self.parent.webView = webView
    
                webView.load(URLRequest(url: self.parent.url))
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        context.coordinator.configureWebView(webView)
        
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.load(URLRequest(url: url))
        webView.pageZoom = zoom / 100
    }
}

class WebViewURLObserver: NSObject, WKNavigationDelegate {
    @Binding var url: URL?
    
    init(url: Binding<URL?>) {
        self._url = url
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let currentURL = webView.url {
            url = currentURL
        }
    }
}

class NavigationDelegate: NSObject, WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        /* if let currentURL = navigationAction.request.url?.absoluteString {
            print("Navigating to URL: \(currentURL)")
        } */
        
        decisionHandler(.allow)
    }
    
    /* func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let currentURL = webView.url?.absoluteString {
            print("Finished loading URL: \(currentURL)")
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Navigation failed with error: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("Provisional navigation failed with error: \(error.localizedDescription)")
    } */
}

struct WebBrowserControlsView: View {
    @Binding var url: URL?
    @State var nextUrlString: String = ""
    @State var isControlsExpanded: Bool = false
    let webView: WKWebView
    var urlObserver: WebViewURLObserver?
    
    init(url: Binding<URL?>, webView: WKWebView) {
        self._url = url
        self._nextUrlString = State(initialValue: url.wrappedValue?.absoluteString ?? "")
        self.webView = webView
        self.urlObserver = WebViewURLObserver(url: url)
        
        webView.navigationDelegate = urlObserver
    }

    func goToUrl() {
        withAnimation {
            url = normalizeUrlString(nextUrlString)
            isControlsExpanded.toggle()
        }
    }
    
    var body: some View {
        VStack {
            if (isControlsExpanded) {
                VStack(spacing: 0) {
                    HStack {
                        Button {
                            webView.goBack()
                        } label: {
                            Label("Go back", systemImage: "chevron.left")
                                .labelStyle(.iconOnly)
                        }
                        .buttonStyle(.plain)
                        .disabled(!webView.canGoBack)
                        
                        Button {
                            webView.goForward()
                        } label: {
                            Label("Go forward", systemImage: "chevron.right")
                                .labelStyle(.iconOnly)
                        }
                        .buttonStyle(.plain)
                        .disabled(!webView.canGoForward)
                        
                        TextField("URL", text: $nextUrlString)
                            .textFieldStyle(.plain)
                            .onSubmit {
                                goToUrl()
                            }
                        
                        Button {
                            goToUrl()
                        } label: {
                            Label("Open URL", systemImage: "magnifyingglass")
                                .labelStyle(.iconOnly)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            url = nil
                            
                            goToUrl()
                        } label: {
                            Label("Reload", systemImage: "arrow.clockwise")
                                .labelStyle(.iconOnly)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(.ultraThickMaterial)
                    .cornerRadius(6)
                    .padding(5)
                }
            }
            
            Button {
                withAnimation {
                    isControlsExpanded.toggle()
                }
            } label: {
                if (isControlsExpanded) {
                    Label("Hide controls", systemImage: "chevron.up")
                        .labelStyle(.iconOnly)
                } else {
                    Label("Show controls", systemImage: "chevron.down")
                        .labelStyle(.iconOnly)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.primary)
        }
        .onAppear {
            nextUrlString = url?.absoluteString ?? ""
            
            if (url == nil) {
                isControlsExpanded = true
            }
        }
        .onChange(of: url) {
            if (url == nil) {
                isControlsExpanded = true
            }
        }
        .onChange(of: webView.url) {
            url = webView.url
        }
    }
}

struct WebBrowserView: View {
    var urlIndex: Int
    var zoom: Double
    @AppStorage("urls") var urls: [String] = []
    @State var url: URL?
    @State var webView: WKWebView = WKWebView()
    
    var body: some View {
        ZStack {
            if let url {
                WebView(url: url, zoom: zoom, webView: $webView)
            } else {
                ContentUnavailableView("Enter URL", systemImage: "globe")
            }
            
            VStack {
                WebBrowserControlsView(url: $url, webView: webView)
                
                Spacer()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .reloadAllWindows)) { _ in
            webView.reload()
        }
        .background(.background)
        .cornerRadius(10)
        .padding(2)
        .onAppear {
            url = normalizeUrlString(urls[safe: urlIndex] ?? "")
        }
        .onChange(of: url) {
            urls[urlIndex] = url?.absoluteString ?? ""
        }
    }
}

struct ContentView: View {
    @AppStorage("urls") var urls: [String] = []
    @AppStorage("columnsCount") var columnsCount: Double = 3
    @AppStorage("rowsCount") var rowsCount: Double = 2
    @AppStorage("zoom") var zoom: Double = 70
    @AppStorage("sideMenuVisibility") var sideMenuVisibility: NavigationSplitViewVisibility = .detailOnly
    
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
    
    func reloadAllWindows() {
        NotificationCenter.default.post(name: .reloadAllWindows, object: nil)
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $sideMenuVisibility) {
            NoWindowsMessageView(urls: $urls)
            
            if (!urls.isEmpty) {
                List {
                    Section("Opened windows") {
                        ForEach(urls, id: \.self) { urlString in
                            Text(formatUrlString(urlString))
                                .contextMenu {
                                    Button("Close window") {
                                        closeWindow(urlString)
                                    }
                                }
                        }
                    }
                }
            }
        } detail: {
            NoWindowsMessageView(urls: $urls)
            
            if (!urls.isEmpty) {
                GeometryReader { geometry in
                    LazyVGrid(columns: columns, spacing: 0) {
                        ForEach(0..<urls.count, id: \.self) { urlIndex in
                            WebBrowserView(urlIndex: urlIndex, zoom: zoom)
                                .frame(height: geometry.size.height / rowsCount)
                        }
                    }
                    .padding(3)
                }
            }
        }
        .toolbar {
            ToolbarAction_openNewWindow { openNewWindow() }
            ToolbarAction_columnsCount(columnsCount: $columnsCount)
            ToolbarAction_rowsCount(rowsCount: $rowsCount)
            ToolbarAction_zoom(zoom: $zoom)
            ToolbarAction_reloadAllWindows { reloadAllWindows() }
            ToolbarAction_closeAllWindows { closeAllWindows() }
        }
    }
}

#Preview(traits: .fixedLayout(width: 1920, height: 1080)) {
    ContentView()
}
