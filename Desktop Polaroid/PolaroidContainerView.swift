import SwiftUI

struct PolaroidContainerView: View {
    @EnvironmentObject var polaroidManager: PolaroidManager
    @State private var currentPolaroidId: UUID?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(polaroidManager.polaroids) { polaroid in
                    PolaroidView(polaroid: polaroid)
                        .position(polaroid.position)
                        .rotationEffect(.degrees(polaroid.rotation))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                // 自动创建新窗口用于显示拍立得
                for polaroid in polaroidManager.polaroids {
                    openPolaroidWindow(polaroid)
                }
            }
            .onChange(of: polaroidManager.polaroids.count) { oldCount, newCount in
                // 当有新的拍立得创建时，打开新窗口
                if newCount > oldCount, let lastPolaroid = polaroidManager.polaroids.last {
                    openPolaroidWindow(lastPolaroid)
                }
            }
        }
    }
    
    private func openPolaroidWindow(_ polaroid: Polaroid) {
        // 创建新的窗口来显示拍立得
        if let window = NSApplication.shared.windows.first(where: { $0.title == "polaroid_\(polaroid.id)" }) {
            // 窗口已存在，更新位置
            window.setFrameOrigin(polaroid.position)
        } else {
            // 创建新窗口
            let polaroidView = PolaroidView(polaroid: polaroid)
                .environmentObject(polaroidManager)
                .frame(width: polaroid.size.width, height: polaroid.size.height)
            
            let hostingView = NSHostingView(rootView: polaroidView)
            let window = NSWindow(
                contentRect: NSRect(origin: polaroid.position, size: polaroid.size),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            
            window.title = "polaroid_\(polaroid.id)"
            window.contentView = hostingView
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = true
            
            let desktopLevel = NSWindow.Level(Int(CGWindowLevelForKey(.desktopWindow)) + 1)
            window.level = desktopLevel
            
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
            window.makeKeyAndOrderFront(nil)
        }
    }
}
