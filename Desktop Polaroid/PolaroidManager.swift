import SwiftUI
import Combine
import AppKit

class PolaroidManager: ObservableObject {
    @Published var polaroids: [Polaroid] = []
    @Published var selectedPolaroid: Polaroid?
    
    private let saveKey = "savedPolaroids"
    private var activeWindows: [UUID: NSWindow] = [:]
    
    init() {
        loadPolaroids()
        restoreWindows()
    }
    
    func addPolaroid(_ polaroid: Polaroid) {
        polaroids.append(polaroid)
        savePolaroidsWithoutImageData() // 只保存元数据，不保存图片数据
        createWindowForPolaroid(polaroid)
    }
    
    func updatePolaroid(_ polaroid: Polaroid) {
        if let index = polaroids.firstIndex(where: { $0.id == polaroid.id }) {
            polaroids[index] = polaroid
            savePolaroidsWithoutImageData() // 只保存元数据
            updateWindowForPolaroid(polaroid)
        }
    }
    
    func removePolaroid(_ polaroid: Polaroid) {
        closeWindowForPolaroid(polaroid.id)
        polaroids.removeAll { $0.id == polaroid.id }
        savePolaroidsWithoutImageData()
    }
    
    func createNewPolaroid() -> Polaroid {
        let polaroid = Polaroid()
        addPolaroid(polaroid)
        return polaroid
    }
    
    // 只保存元数据，不保存图片数据
    private func savePolaroidsWithoutImageData() {
        do {
            // 创建只包含元数据的拍立得副本
            let polaroidsWithoutImages = polaroids.map { polaroid -> Polaroid in
                var polaroidCopy = polaroid
                polaroidCopy.imageData = nil // 不保存图片数据
                return polaroidCopy
            }
            
            let encoder = JSONEncoder()
            let data = try encoder.encode(polaroidsWithoutImages)
            
            // 检查数据大小
            if data.count > 4_194_304 {
                print("Warning: Data size (\(data.count) bytes) exceeds 4MB limit")
                // 尝试压缩
                if let compressed = try? (data as NSData).compressed(using: .zlib) {
                    UserDefaults.standard.set(compressed, forKey: saveKey + "_compressed")
                    print("Saved compressed data: \(compressed.length) bytes")
                }
            } else {
                UserDefaults.standard.set(data, forKey: saveKey)
            }
            
            // 单独保存图片到文件系统
            saveImagesToFileSystem()
            
        } catch {
            print("Failed to save polaroids: \(error)")
        }
    }
    
    private func saveImagesToFileSystem() {
        // 创建图片存储目录
        let fileManager = FileManager.default
        let imagesDirectory = getImagesDirectory()
        
        do {
            // 确保目录存在
            if !fileManager.fileExists(atPath: imagesDirectory.path) {
                try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
            }
            
            // 保存每张图片
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
        // 首先尝试加载压缩的数据
        if let compressedData = UserDefaults.standard.data(forKey: saveKey + "_compressed") {
            do {
                let decompressed = try (compressedData as NSData).decompressed(using: .zlib)
                let decoder = JSONDecoder()
                var loadedPolaroids = try decoder.decode([Polaroid].self, from: decompressed as Data)
                
                // 加载图片数据
                loadImagesFromFileSystem(into: &loadedPolaroids)
                
                polaroids = loadedPolaroids
                return
            } catch {
                print("Failed to load compressed polaroids: \(error)")
            }
        }
        
        // 尝试加载普通数据
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }
        do {
            let decoder = JSONDecoder()
            var loadedPolaroids = try decoder.decode([Polaroid].self, from: data)
            
            // 加载图片数据
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
    
    // 公开的保存方法供外部调用
    func savePolaroids() {
        savePolaroidsWithoutImageData()
    }
    
    private func restoreWindows() {
        for polaroid in polaroids {
            createWindowForPolaroid(polaroid)
        }
    }
    
    private func createWindowForPolaroid(_ polaroid: Polaroid) {
        // 避免重复创建窗口
        guard activeWindows[polaroid.id] == nil else { return }
        
        let contentView = PolaroidView(polaroid: polaroid)
            .environmentObject(self)
        
        let hostingView = NSHostingView(rootView: contentView)
        
        // 创建自定义窗口类来处理成为关键窗口的行为
        let window = PolaroidWindow(
            contentRect: NSRect(
                origin: NSPoint(x: polaroid.position.x, y: polaroid.position.y),
                size: NSSize(width: polaroid.size.width, height: polaroid.size.height)
            ),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.title = "polaroid_\(polaroid.id)"
        window.contentView = hostingView
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        
        // 使窗口忽略鼠标事件，让内容视图处理
        window.ignoresMouseEvents = false
        
        window.makeKeyAndOrderFront(nil)
        
        // 保存窗口引用
        activeWindows[polaroid.id] = window
        
        // 监听窗口关闭
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            if let window = notification.object as? NSWindow,
               let (id, _) = self.activeWindows.first(where: { $0.value === window }) {
                // 当窗口关闭时，从管理器中移除对应的拍立得
                self.polaroids.removeAll { $0.id == id }
                self.activeWindows.removeValue(forKey: id)
                self.savePolaroidsWithoutImageData()
                
                // 删除对应的图片文件
                self.deleteImageFile(for: id)
            }
        }
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
        
        // 更新窗口位置和大小
        window.setFrame(
            NSRect(
                origin: NSPoint(x: polaroid.position.x, y: polaroid.position.y),
                size: NSSize(width: polaroid.size.width, height: polaroid.size.height)
            ),
            display: true
        )
        
        // 更新窗口内容
        let contentView = PolaroidView(polaroid: polaroid)
            .environmentObject(self)
        window.contentView = NSHostingView(rootView: contentView)
    }
    
    private func closeWindowForPolaroid(_ id: UUID) {
        if let window = activeWindows[id] {
            window.close()
            activeWindows.removeValue(forKey: id)
        }
    }
}

// 自定义窗口类，重写 canBecomeKey 和 canBecomeMain 方法
class PolaroidWindow: NSWindow {
    override var canBecomeKey: Bool {
        return false
    }
    
    override var canBecomeMain: Bool {
        return false
    }
    
    // 允许窗口接收鼠标事件
    override func mouseDown(with event: NSEvent) {
        // 将鼠标事件传递给内容视图
        contentView?.mouseDown(with: event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        contentView?.mouseDragged(with: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        contentView?.mouseUp(with: event)
    }
}
