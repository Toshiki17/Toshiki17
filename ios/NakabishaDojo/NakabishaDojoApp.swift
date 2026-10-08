import SwiftUI

@main
struct NakabishaDojoApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color("AppBackground").ignoresSafeArea()
                // 上はステータスバーの下から。下は端まで広げ、ホームバー分の余白はページ側（env(safe-area-inset-bottom)）で取る
                DojoWebView().ignoresSafeArea(.container, edges: .bottom)
            }
        }
    }
}
