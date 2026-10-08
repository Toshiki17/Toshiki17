import SwiftUI
import WebKit

/// 同梱した www/index.html を表示する。
/// file:// ではなく独自スキーム（app://local/）で配信し、localStorage（クリア記録・腕試しの成績）が確実に残るようにする。
struct DojoWebView: UIViewRepresentable {
    static let scheme = "app"
    static let startURL = URL(string: "\(scheme)://local/index.html")!

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.setURLSchemeHandler(BundleSchemeHandler(), forURLScheme: Self.scheme)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsLinkPreview = false
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: Self.startURL))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
        // 同梱ページ以外へは移動させず、外部リンクはSafariで開く
        func webView(_ webView: WKWebView,
                     decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = action.request.url else { return decisionHandler(.cancel) }
            if url.scheme == DojoWebView.scheme || url.scheme == "about" {
                decisionHandler(.allow)
            } else {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            }
        }

        // target="_blank" のリンクも同じ扱いにする
        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for action: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = action.request.url { UIApplication.shared.open(url) }
            return nil
        }

        // メモリ不足などでページの処理が止まったら読み直す
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            webView.load(URLRequest(url: DojoWebView.startURL))
        }

        func webView(_ webView: WKWebView,
                     runJavaScriptAlertPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo,
                     completionHandler: @escaping () -> Void) {
            present(UIAlertController(title: nil, message: message, preferredStyle: .alert),
                    actions: [UIAlertAction(title: "OK", style: .default) { _ in completionHandler() }],
                    from: webView, fallback: completionHandler)
        }

        func webView(_ webView: WKWebView,
                     runJavaScriptConfirmPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo,
                     completionHandler: @escaping (Bool) -> Void) {
            present(UIAlertController(title: nil, message: message, preferredStyle: .alert),
                    actions: [UIAlertAction(title: "キャンセル", style: .cancel) { _ in completionHandler(false) },
                              UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) }],
                    from: webView, fallback: { completionHandler(false) })
        }

        private func present(_ alert: UIAlertController, actions: [UIAlertAction],
                             from view: UIView, fallback: @escaping () -> Void) {
            actions.forEach(alert.addAction)
            var top = view.window?.rootViewController
            while let next = top?.presentedViewController { top = next }
            guard let top else { return fallback() }
            top.present(alert, animated: true)
        }
    }
}

/// app://local/<path> を、アプリに同梱した www フォルダのファイルとして返す。
final class BundleSchemeHandler: NSObject, WKURLSchemeHandler {
    private let root = Bundle.main.resourceURL!.appendingPathComponent("www", isDirectory: true)

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url else { return }
        var path = url.path
        if path.isEmpty || path == "/" { path = "/index.html" }
        let file = root.appendingPathComponent(String(path.dropFirst())).standardizedFileURL

        guard file.path.hasPrefix(root.standardizedFileURL.path),
              let data = try? Data(contentsOf: file) else {
            task.didFailWithError(URLError(.fileDoesNotExist))
            return
        }
        let headers = [
            "Content-Type": Self.mimeType(for: file.pathExtension),
            "Content-Length": String(data.count),
            "Cache-Control": "no-cache",
        ]
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)!
        task.didReceive(response)
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}

    private static func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "html": return "text/html; charset=utf-8"
        case "css": return "text/css; charset=utf-8"
        case "js": return "text/javascript; charset=utf-8"
        case "json": return "application/json"
        case "woff2": return "font/woff2"
        case "png": return "image/png"
        case "svg": return "image/svg+xml"
        default: return "application/octet-stream"
        }
    }
}
