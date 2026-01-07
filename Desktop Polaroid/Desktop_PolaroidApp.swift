import SwiftUI
import Combine

@main
struct Desktop_PolaroidApp: App {
    @StateObject private var polaroidManager = PolaroidManager()
    @AppStorage("hasShownWelcome") private var hasShownWelcome = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(polaroidManager)
                .onAppear {
                    if !hasShownWelcome {
                        hasShownWelcome = true
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
