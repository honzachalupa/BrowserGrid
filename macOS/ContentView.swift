import SwiftUI
@preconcurrency import WebKit

struct WebView: NSViewRepresentable {
    var url: String
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
                
                if let validUrl = URL(string: self.parent.url) {
                    webView.load(URLRequest(url: validUrl))
                }
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
        if let validUrl = URL(string: url), webView.url?.absoluteString != url {
            webView.load(URLRequest(url: validUrl))
        }
        
        webView.pageZoom = zoom / 100
    }
}

class WebViewURLObserver: NSObject, WKNavigationDelegate {
    @Binding var url: String
    
    init(url: Binding<String>) {
        self._url = url
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let currentURL = webView.url?.absoluteString {
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
    @Binding var url: String
    @State var nextUrl: String = ""
    @State var isControlsExpanded: Bool = false
    let webView: WKWebView
    var urlObserver: WebViewURLObserver?
    
    init(url: Binding<String>, webView: WKWebView) {
        self._url = url
        self.webView = webView
        self._nextUrl = State(initialValue: url.wrappedValue)
        self.urlObserver = WebViewURLObserver(url: url)
        
        // Set the navigation delegate
        webView.navigationDelegate = urlObserver
    }

    func submitUrl() {
        withAnimation {
            url = nextUrl
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
                        
                        TextField("URL", text: $nextUrl)
                            .textFieldStyle(.plain)
                            .onSubmit {
                                submitUrl()
                            }
                        
                        Button {
                            submitUrl()
                        } label: {
                            Label("Open URL", systemImage: "magnifyingglass")
                                .labelStyle(.iconOnly)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            url = ""
                            
                            submitUrl()
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
            nextUrl = url
            
            if (url.isEmpty) {
                isControlsExpanded = true
            }
        }
        .onChange(of: url) {
            if (url.isEmpty) {
                isControlsExpanded = true
            }
        }
        .onChange(of: webView.url?.absoluteString) {
            url = webView.url?.absoluteString ?? ""
        }
    }
}

struct WebBrowserView: View {
    var urlIndex: Int
    var zoom: Double
    @AppStorage("urls") var urls: [String] = []
    @State var url: String = ""
    @State var webView: WKWebView = WKWebView()
    
    var persistedUrl: String {
        urls[safe: urlIndex] ?? ""
    }
    
    var body: some View {
        ZStack {
            if url.isEmpty {
                ContentUnavailableView("", systemImage: "globe", description: Text("Enter URL"))
            } else {
                WebView(url: persistedUrl, zoom: zoom, webView: $webView)
                    .cornerRadius(10)
                    .padding(2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            VStack {
                WebBrowserControlsView(url: $url, webView: webView)
                
                Spacer()
            }
        }
        .onAppear {
            url = persistedUrl
        }
        .onChange(of: url) {
            urls[urlIndex] = url
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
            repeating: GridItem(.flexible(minimum: 100), spacing: 0),
            count: Int(columnsCount)
        )
    }
    
    func formatUrl(_ url: String) -> String {
        return url.replacing(/^https?:\/\//, with: "").replacing(/\/$/, with: "")
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $sideMenuVisibility) {
            HStack {
                Button {
                    urls.append("")
                } label: {
                    Label("New window", systemImage: "plus")
                }
                .buttonStyle(.borderless)
                .padding(12)
                
                Spacer()
            }
            
            if urls.isEmpty {
                Text("No windows opened yet.")
                    .padding(.top, 20)

                Spacer()
            } else {
                List {
                    Section("Opened windows") {
                        ForEach(urls, id: \.self) { url in
                            Text(formatUrl(url))
                                .contextMenu {
                                    Button("Close window") {
                                        urls.removeAll { $0 == url }
                                    }
                                }
                        }
                    }
                }
            }
        } detail: {
            VStack {
                GeometryReader { geometry in
                    LazyVGrid(columns: columns, spacing: 0) {
                        ForEach(0..<urls.count, id: \.self) { urlIndex in
                            WebBrowserView(urlIndex: urlIndex, zoom: zoom)
                                .frame(height: geometry.size.height / rowsCount)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        urls.append("")
                    } label: {
                        Label("New window", systemImage: "plus")
                    }
                }
                
                ToolbarItem(placement: .status) {
                    HStack {
                        Text("Columns:")
                        Text(String(format: "%.0f", columnsCount))
                        Stepper("Columns", value: $columnsCount, step: 1)
                    }
                }
                
                ToolbarItem(placement: .status) {
                    HStack {
                        Text("Rows:")
                        Text(String(format: "%.0f", rowsCount))
                        Stepper("Rows", value: $rowsCount, step: 1)
                    }
                }
                
                ToolbarItem(placement: .status) {
                    HStack {
                        Text("Zoom:")
                        Slider(value: $zoom, in: 50.0...100.0, step: 5)
                            .frame(width: 150)
                        Text("\(String(format: "%.0f", zoom)) %")
                    }
                    .padding(.leading, 20)
                }
                
                ToolbarItem {
                    Button {
                        // TODO: Reload all windows
                    } label: {
                        Label("Reload all windows", systemImage: "arrow.clockwise")
                    }
                }
                
                ToolbarItem {
                    Button {
                        urls = []
                    } label: {
                        Label("Close all windows", systemImage: "trash")
                    }
                }
            }
        }
    }
}

#Preview(traits: .fixedLayout(width: 1920, height: 1080)) {
    ContentView()
}
