import SwiftUI
import AppKit
import Combine

// 自定义窗口类，重写 canBecomeKey 和 canBecomeMain 方法
class PolaroidWindow: NSPanel {
    override var canBecomeKey: Bool {
        return false
    }
    
    override var canBecomeMain: Bool {
        return false
    }
    
    // 初始化方法
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        setupWindow()
    }
    
    private func setupWindow() {
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        
        // 关键设置：使用原始值设置桌面级别
        // 桌面窗口的原始层级值
        let desktopWindowLevel = Int(CGWindowLevelForKey(.desktopWindow))
        let desktopIconWindowLevel = Int(CGWindowLevelForKey(.desktopIconWindow))
        
        // 设置在我们自己的层级（在桌面图标上方）
        let customDesktopLevel = max(desktopWindowLevel, desktopIconWindowLevel) + 20
        self.level = NSWindow.Level(rawValue: customDesktopLevel)
        
        // 设置窗口行为
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        self.isReleasedWhenClosed = false
        
        // 禁用窗口调整大小和移动
        self.isMovableByWindowBackground = false
        self.styleMask.remove(.resizable)
        
        // 禁用标题栏和标准窗口控件
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
        
        // 允许窗口接收鼠标事件
        self.ignoresMouseEvents = false
    }
    
    // 修正：正确重写 canBecomeVisibleWithoutLogin 属性
    override var canBecomeVisibleWithoutLogin: Bool {
        get {
            return true
        }
        set {
            super.canBecomeVisibleWithoutLogin = newValue
        }
    }
}

// 确保 PolaroidManager 正确遵循 ObservableObject
class PolaroidManager: ObservableObject {
    // @Published 属性必须正确声明
    @Published var polaroids: [Polaroid] = []
    @Published var selectedPolaroid: Polaroid?
    
    private let saveKey = "savedPolaroids"
    private var activeWindows: [UUID: PolaroidWindow] = [:]
    
    init() {
        loadPolaroids()
        restoreWindows()
    }
    
    // 确保所有 public 方法都在这里声明
    func addPolaroid(_ polaroid: Polaroid) {
        polaroids.append(polaroid)
        savePolaroidsWithoutImageData()
        createWindowForPolaroid(polaroid)
    }
    
    func updatePolaroid(_ polaroid: Polaroid) {
        if let index = polaroids.firstIndex(where: { $0.id == polaroid.id }) {
            polaroids[index] = polaroid
            savePolaroidsWithoutImageData()
            updateWindowForPolaroid(polaroid)
        }
    }
    
    func removePolaroid(_ polaroid: Polaroid) {
        closeWindowForPolaroid(polaroid.id)
        polaroids.removeAll { $0.id == polaroid.id }
        savePolaroidsWithoutImageData()
        deleteImageFile(for: polaroid.id)
    }
    
    func closeWindowForPolaroid(_ id: UUID) {
        if let window = activeWindows[id] {
            window.close()
            activeWindows.removeValue(forKey: id)
        }
    }
    
    func reopenPolaroid(_ polaroid: Polaroid) {
        createWindowForPolaroid(polaroid)
    }
    
    func createNewPolaroid() -> Polaroid {
        let polaroid = Polaroid()
        addPolaroid(polaroid)
        return polaroid
    }
    
    func isWindowOpen(for polaroidId: UUID) -> Bool {
        return activeWindows[polaroidId] != nil
    }
    
    func savePolaroids() {
        savePolaroidsWithoutImageData()
    }
    
    // MARK: - Private Methods
    
    private func savePolaroidsWithoutImageData() {
        do {
            let polaroidsWithoutImages = polaroids.map { polaroid -> Polaroid in
                var polaroidCopy = polaroid
                polaroidCopy.imageData = nil
                return polaroidCopy
            }
            
            let encoder = JSONEncoder()
            let data = try encoder.encode(polaroidsWithoutImages)
            
            if data.count > 4_194_304 {
                print("Warning: Data size (\(data.count) bytes) exceeds 4MB limit")
                if let compressed = try? (data as NSData).compressed(using: .zlib) {
                    UserDefaults.standard.set(compressed, forKey: saveKey + "_compressed")
                    print("Saved compressed data: \(compressed.length) bytes")
                }
            } else {
                UserDefaults.standard.set(data, forKey: saveKey)
            }
            
            saveImagesToFileSystem()
            
        } catch {
            print("Failed to save polaroids: \(error)")
        }
    }
    
    private func saveImagesToFileSystem() {
        let fileManager = FileManager.default
        let imagesDirectory = getImagesDirectory()
        
        do {
            if !fileManager.fileExists(atPath: imagesDirectory.path) {
                try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
            }
            
            for polaroid in polaroids {
                guard let imageData = polaroid.imageData else { continue }
                let imageURL = imagesDirectory.appendingPathComponent("\(polaroid.id.uuidString).png")
                
                do {
                    try imageData.write(to: imageURL)
                } catch {
                    print("Failed to save image for polaroid \(polaroid.id): \(error)")
                }
            }
            
        } catch {
            print("Failed to create images directory: \(error)")
        }
    }
    
    private func loadPolaroids() {
        if let compressedData = UserDefaults.standard.data(forKey: saveKey + "_compressed") {
            do {
                let decompressed = try (compressedData as NSData).decompressed(using: .zlib)
                let decoder = JSONDecoder()
                var loadedPolaroids = try decoder.decode([Polaroid].self, from: decompressed as Data)
                
                loadImagesFromFileSystem(into: &loadedPolaroids)
                
                polaroids = loadedPolaroids
                return
            } catch {
                print("Failed to load compressed polaroids: \(error)")
            }
        }
        
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }
        do {
            let decoder = JSONDecoder()
            var loadedPolaroids = try decoder.decode([Polaroid].self, from: data)
            
            loadImagesFromFileSystem(into: &loadedPolaroids)
            
            polaroids = loadedPolaroids
        } catch {
            print("Failed to load polaroids: \(error)")
        }
    }
    
    private func loadImagesFromFileSystem(into polaroids: inout [Polaroid]) {
        let imagesDirectory = getImagesDirectory()
        
        for i in 0..<polaroids.count {
            let polaroid = polaroids[i]
            let imageURL = imagesDirectory.appendingPathComponent("\(polaroid.id.uuidString).png")
            
            if FileManager.default.fileExists(atPath: imageURL.path) {
                do {
                    let imageData = try Data(contentsOf: imageURL)
                    polaroids[i].imageData = imageData
                } catch {
                    print("Failed to load image for polaroid \(polaroid.id): \(error)")
                }
            }
        }
    }
    
    private func getImagesDirectory() -> URL {
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupportURL.appendingPathComponent("DesktopPolaroid")
        return appDirectory.appendingPathComponent("Images")
    }
    
    private func restoreWindows() {
        for polaroid in polaroids {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.createWindowForPolaroid(polaroid)
            }
        }
    }
    
    private func createWindowForPolaroid(_ polaroid: Polaroid) {
        guard activeWindows[polaroid.id] == nil else { return }
        
        let contentView = PolaroidView(polaroid: polaroid)
            .environmentObject(self)
        
        let hostingView = NSHostingView(rootView: contentView)
        
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.visibleFrame
        
        var windowX = polaroid.position.x
        var windowY = polaroid.position.y
        
        if windowX < screenRect.minX {
            windowX = screenRect.minX + 50
        }
        if windowY < screenRect.minY {
            windowY = screenRect.minY + 50
        }
        if windowX + polaroid.size.width > screenRect.maxX {
            windowX = screenRect.maxX - polaroid.size.width - 50
        }
        if windowY + polaroid.size.height > screenRect.maxY {
            windowY = screenRect.maxY - polaroid.size.height - 50
        }
        
        let window = PolaroidWindow(
            contentRect: NSRect(
                origin: NSPoint(x: windowX, y: windowY),
                size: NSSize(width: polaroid.size.width, height: polaroid.size.height)
            ),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.title = "polaroid_\(polaroid.id)"
        window.contentView = hostingView
        
        // 修正：使用正确的窗口级别
        let desktopWindowLevel = Int(CGWindowLevelForKey(.desktopWindow))
        let desktopIconWindowLevel = Int(CGWindowLevelForKey(.desktopIconWindow))
        let customDesktopLevel = max(desktopWindowLevel, desktopIconWindowLevel) + 20
        window.level = NSWindow.Level(rawValue: customDesktopLevel)
        
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        
        activeWindows[polaroid.id] = window
        
        // 简化通知处理，避免并发问题
        let polaroidId = polaroid.id
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            // 直接移除对应ID的窗口
            self.activeWindows.removeValue(forKey: polaroidId)
        }
        
        print("窗口已创建: \(polaroid.id), 位置: \(windowX), \(windowY)")
    }
    
    private func deleteImageFile(for id: UUID) {
        let imagesDirectory = getImagesDirectory()
        let imageURL = imagesDirectory.appendingPathComponent("\(id.uuidString).png")
        
        do {
            if FileManager.default.fileExists(atPath: imageURL.path) {
                try FileManager.default.removeItem(at: imageURL)
            }
        } catch {
            print("Failed to delete image file for polaroid \(id): \(error)")
        }
    }
    
    private func updateWindowForPolaroid(_ polaroid: Polaroid) {
        guard let window = activeWindows[polaroid.id] else { return }
        
        window.setFrame(
            NSRect(
                origin: NSPoint(x: polaroid.position.x, y: polaroid.position.y),
                size: NSSize(width: polaroid.size.width, height: polaroid.size.height)
            ),
            display: true
        )
        
        let contentView = PolaroidView(polaroid: polaroid)
            .environmentObject(self)
        window.contentView = NSHostingView(rootView: contentView)
    }
}
