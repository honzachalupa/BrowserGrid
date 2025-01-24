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
                            Label("Open URL", systemImage: "chevron.right")
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
        }
    }
}

struct WebBrowserView: View {
    @Binding var url: String
    var zoom: Double
    @State private var webView: WKWebView = WKWebView()
    
    var body: some View {
        VStack {
            if url.isEmpty {
                ContentUnavailableView("Enter URL", systemImage: "magnifyingglass")
            } else {
                WebView(url: url, zoom: zoom, webView: $webView)
                    .cornerRadius(10)
                    .padding(2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .overlay {
            VStack {
                WebBrowserControlsView(url: $url, webView: webView)
                
                Spacer()
            }
        }
    }
}

enum LayoutVariant: CaseIterable {
    case x2_y1, x2_y2, x3_y2, x3_y3, x4_y2, x4_y3
    
    var label: String {
        switch self {
            case .x2_y1:
                return "2:1"
            case .x2_y2:
                return "2:2"
            case .x3_y2:
                return "3:2"
            case .x3_y3:
                return "3:3"
            case .x4_y2:
                return "4:2"
            case .x4_y3:
                return "4:3"
        }
    }
    
    var gridColumns: [GridItem] {
        switch self {
            case .x2_y1, .x2_y2:
                return [
                    GridItem(.flexible(minimum: 100), spacing: 0),
                    GridItem(.flexible(minimum: 100), spacing: 0)
                ]
            case .x3_y2, .x3_y3:
                return [
                    GridItem(.flexible(minimum: 100), spacing: 0),
                    GridItem(.flexible(minimum: 100), spacing: 0),
                    GridItem(.flexible(minimum: 100), spacing: 0)
                ]
            case .x4_y2, .x4_y3:
                return [
                    GridItem(.flexible(minimum: 100), spacing: 0),
                    GridItem(.flexible(minimum: 100), spacing: 0),
                    GridItem(.flexible(minimum: 100), spacing: 0),
                    GridItem(.flexible(minimum: 100), spacing: 0)
                ]
        }
    }
    
    var gridRowHeightDivider: CGFloat {
        switch self {
            case .x2_y1:
                return 1
            case .x2_y2, .x3_y2, .x4_y2:
                return 2
            case .x3_y3, .x4_y3:
                return 3
        }
    }
}

struct ContentView: View {
    @State var layoutVariant: LayoutVariant? = .x3_y2 // TODO: Make it persistent using AppStorage
    @AppStorage("zoom") var zoom: Double = 70
    
    @AppStorage("url1") var url1: String = ""
    @AppStorage("url2") var url2: String = ""
    @AppStorage("url3") var url3: String = ""
    @AppStorage("url4") var url4: String = ""
    @AppStorage("url5") var url5: String = ""
    @AppStorage("url6") var url6: String = ""
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                if let gridColumns = layoutVariant?.gridColumns, let gridRowHeightDivider = layoutVariant?.gridRowHeightDivider {
                    LazyVGrid(columns: gridColumns, spacing: 0) {
                        WebBrowserView(url: $url1, zoom: zoom)
                            .frame(height: geometry.size.height / gridRowHeightDivider)
                        WebBrowserView(url: $url2, zoom: zoom)
                            .frame(height: geometry.size.height / gridRowHeightDivider)
                        WebBrowserView(url: $url3, zoom: zoom)
                            .frame(height: geometry.size.height / gridRowHeightDivider)
                        WebBrowserView(url: $url4, zoom: zoom)
                            .frame(height: geometry.size.height / gridRowHeightDivider)
                        WebBrowserView(url: $url5, zoom: zoom)
                            .frame(height: geometry.size.height / gridRowHeightDivider)
                        WebBrowserView(url: $url6, zoom: zoom)
                            .frame(height: geometry.size.height / gridRowHeightDivider)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .status) {
                HStack {
                    Text("Layout:")
                    Picker("", selection: $layoutVariant) {
                        ForEach(LayoutVariant.allCases, id: \.self) { layoutVariant in
                            Text(layoutVariant.label)
                                .tag(layoutVariant)
                        }
                    }
                }
            }
            
            ToolbarItem(placement: .status) {
                HStack {
                    Text("Zoom:")
                    Slider(value: $zoom, in: 50.0...100.0, step: 5)
                        .frame(width: 200)
                    Text("\(String(format: "%.0f", zoom)) %")
                }
                .padding(.leading, 20)
            }
        }
    }
}

#Preview(traits: .fixedLayout(width: 1920, height: 1080)) {
    ContentView()
}
