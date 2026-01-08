import SwiftUI
import UniformTypeIdentifiers

struct CreatePolaroidView: View {
    @EnvironmentObject var polaroidManager: PolaroidManager
    @State private var showingImagePicker = false
    @State private var selectedImage: NSImage?
    @State private var newPolaroid = Polaroid()
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧：设置面板 - 增加宽度
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // 标题
                    VStack(alignment: .leading, spacing: 5) {
                        Text("创建新拍立得")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("选择照片并自定义相框样式")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // 图片选择区域
                    VStack(alignment: .leading, spacing: 15) {
                        Text("选择图片")
                            .font(.headline)
                        
                        HStack(spacing: 30) {
                            // 图片预览
                            ZStack {
                                if let image = selectedImage {
                                    Image(nsImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 200, height: 200)
                                        .clipped()
                                        .cornerRadius(12)
                                        .shadow(radius: 5)
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: 200, height: 200)
                                        .overlay(
                                            VStack(spacing: 15) {
                                                Image(systemName: "photo.on.rectangle.angled")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(.gray)
                                                Text("点击选择或拖放图片")
                                                    .font(.headline)
                                                    .foregroundColor(.gray)
                                            }
                                        )
                                        .shadow(radius: 2)
                                }
                            }
                            .onTapGesture {
                                showingImagePicker = true
                            }
                            .onDrop(of: [UTType.image], isTargeted: nil) { providers in
                                handleImageDrop(providers: providers)
                                return true
                            }
                            
                            // 图片信息
                            VStack(alignment: .leading, spacing: 20) {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("图片信息")
                                        .font(.headline)
                                    
                                    if selectedImage != nil {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                            Text("已选择图片")
                                                .foregroundColor(.green)
                                        }
                                    } else {
                                        Text("未选择图片")
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("支持格式")
                                        .font(.headline)
                                    Text("JPEG, PNG, HEIC, GIF, TIFF")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("选择图片") {
                                    showingImagePicker = true
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                            }
                            .padding(.vertical, 20)
                        }
                    }
                    
                    Divider()
                    
                    // 相框设置
                    VStack(alignment: .leading, spacing: 25) {
                        Text("相框设置")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        // 颜色选择
                        VStack(alignment: .leading, spacing: 10) {
                            Text("相框颜色")
                                .font(.headline)
                            HStack {
                                ForEach([Color.white, Color.yellow, Color.pink, Color.blue, Color.green], id: \.self) { color in
                                    Circle()
                                        .fill(color)
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.primary.opacity(0.3), lineWidth: color == newPolaroid.frameColor ? 3 : 0)
                                        )
                                        .onTapGesture {
                                            newPolaroid.frameColor = color
                                        }
                                        .padding(2)
                                }
                                
                                ColorPicker("自定义", selection: $newPolaroid.frameColor, supportsOpacity: false)
                                    .labelsHidden()
                            }
                        }
                        
                        // 尺寸设置
                        VStack(alignment: .leading, spacing: 15) {
                            Text("相框尺寸")
                                .font(.headline)
                            
                            HStack {
                                Text("宽度: \(Int(newPolaroid.size.width))px")
                                Slider(value: $newPolaroid.size.width, in: 200...500, step: 10)
                                    .frame(width: 250)
                            }
                            
                            HStack {
                                Text("高度: \(Int(newPolaroid.size.height))px")
                                Slider(value: $newPolaroid.size.height, in: 250...600, step: 10)
                                    .frame(width: 250)
                            }
                        }
                        
                        // 其他设置
                        VStack(alignment: .leading, spacing: 15) {
                            Text("效果设置")
                                .font(.headline)
                            
                            HStack {
                                Text("边框宽度: \(Int(newPolaroid.frameWidth))px")
                                Slider(value: $newPolaroid.frameWidth, in: 10...50, step: 5)
                                    .frame(width: 250)
                            }
                            
                            HStack {
                                Text("阴影大小: \(Int(newPolaroid.shadowRadius))px")
                                Slider(value: $newPolaroid.shadowRadius, in: 0...20, step: 1)
                                    .frame(width: 250)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // 照片信息
                    VStack(alignment: .leading, spacing: 20) {
                        Text("照片信息")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("标题")
                                    .font(.headline)
                                TextField("为您的照片添加一个标题...", text: $newPolaroid.title)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 300)
                            }
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("日期")
                                    .font(.headline)
                                DatePicker("", selection: $newPolaroid.date, displayedComponents: .date)
                                    .labelsHidden()
                            }
                        }
                    }
                    
                    // 创建按钮
                    HStack {
                        Spacer()
                        Button(action: createPolaroid) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("创建拍立得贴纸")
                                    .fontWeight(.semibold)
                            }
                            .frame(width: 250, height: 50)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(selectedImage == nil)
                        Spacer()
                    }
                    .padding(.vertical, 30)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
            .frame(width: 500) // 增加宽度从 450 到 500
            .background(Color.gray.opacity(0.05))
            
            // 右侧：实时预览
            VStack {
                Text("预览")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 20)
                
                // 预览区域 - 调整大小
                CreatePolaroidPreviewView(polaroid: newPolaroid)
                    .frame(width: 380, height: 450) // 增加预览尺寸
                    .padding(.top, 20)
                
                Spacer()
                
                // 预览说明
                VStack(alignment: .leading, spacing: 10) {
                    Text("预览说明")
                        .font(.headline)
                    
                    Text("左侧的修改会实时反映在右侧的预览中。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("点击创建按钮将拍立得添加到桌面。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.03))
        }
        .frame(minWidth: 900, minHeight: 700) // 设置最小窗口尺寸
        .fileImporter(
            isPresented: $showingImagePicker,
            allowedContentTypes: [UTType.image],
            allowsMultipleSelection: false
        ) { result in
            handleImagePickerResult(result)
        }
    }
    
    private func createPolaroid() {
        guard selectedImage != nil else { return }
        
        // 设置默认位置在屏幕中央
        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1440, height: 900)
        newPolaroid.position = CGPoint(
            x: screenSize.width / 2 - newPolaroid.size.width / 2,
            y: screenSize.height / 2 - newPolaroid.size.height / 2
        )
        
        // 添加到管理器 - 这会自动创建窗口
        polaroidManager.addPolaroid(newPolaroid)
        
        // 显示成功提示
        showSuccessMessage()
        
        // 重置表单
        selectedImage = nil
        newPolaroid = Polaroid()
    }
    
    private func showSuccessMessage() {
        let alert = NSAlert()
        alert.messageText = "拍立得已创建"
        alert.informativeText = "拍立得已成功添加到桌面。您可以在管理界面查看和管理所有拍立得。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
    
    private func handleImagePickerResult(_ result: Result<[URL], Error>) {
        do {
            let fileURLs = try result.get()
            if let url = fileURLs.first {
                // 获取访问权限
                let accessed = url.startAccessingSecurityScopedResource()
                defer {
                    if accessed {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                if let image = NSImage(contentsOf: url) {
                    selectedImage = image
                    
                    // 压缩图片以避免 UserDefaults 限制
                    newPolaroid.imageData = compressImage(image, maxSize: CGSize(width: 800, height: 800))
                }
            }
        } catch {
            print("Error selecting image: \(error)")
        }
    }
    
    private func handleImageDrop(providers: [NSItemProvider]) {
        for provider in providers {
            if provider.canLoadObject(ofClass: NSImage.self) {
                _ = provider.loadObject(ofClass: NSImage.self) { image, error in
                    DispatchQueue.main.async {
                        if let nsImage = image as? NSImage {
                            selectedImage = nsImage
                            // 压缩图片
                            newPolaroid.imageData = compressImage(nsImage, maxSize: CGSize(width: 800, height: 800))
                        }
                    }
                }
            }
        }
    }
    
    private func compressImage(_ image: NSImage, maxSize: CGSize) -> Data? {
        // 调整图片尺寸
        let originalSize = image.size
        var newSize = originalSize
        
        // 计算缩放比例
        let widthRatio = maxSize.width / originalSize.width
        let heightRatio = maxSize.height / originalSize.height
        let ratio = min(widthRatio, heightRatio)
        
        if ratio < 1 {
            newSize = CGSize(width: originalSize.width * ratio, height: originalSize.height * ratio)
        }
        
        // 创建新尺寸的图片
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: originalSize),
                   operation: .copy,
                   fraction: 1.0)
        newImage.unlockFocus()
        
        // 转换为 PNG 并压缩
        if let tiffData = newImage.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapImage.representation(using: .png, properties: [.compressionFactor: 0.7]) {
            
            print("Compressed image from \(image.size) to \(newSize), data size: \(pngData.count) bytes")
            
            // 如果还是太大，进一步压缩
            if pngData.count > 2_000_000 { // 2MB
                let smallerSize = CGSize(width: maxSize.width * 0.7, height: maxSize.height * 0.7)
                return compressImage(image, maxSize: smallerSize)
            }
            
            return pngData
        }
        
        return nil
    }
}

// 创建界面的预览组件
struct CreatePolaroidPreviewView: View {
    let polaroid: Polaroid
    
    var body: some View {
        ZStack {
            // 相框
            RoundedRectangle(cornerRadius: 2)
                .fill(polaroid.frameColor)
                .shadow(radius: polaroid.shadowRadius)
            
            VStack(spacing: 0) {
                // 图片区域
                if let nsImage = polaroid.nsImage {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: polaroid.size.width - polaroid.frameWidth * 2,
                               height: polaroid.size.height - polaroid.frameWidth * 2 - 60)
                        .clipped()
                        .padding(polaroid.frameWidth)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: polaroid.size.width - polaroid.frameWidth * 2,
                               height: polaroid.size.height - polaroid.frameWidth * 2 - 60)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                        .padding(polaroid.frameWidth)
                }
                
                // 底部区域
                ZStack {
                    Rectangle()
                        .fill(polaroid.frameColor)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        if !polaroid.title.isEmpty {
                            Text(polaroid.title)
                                .font(.headline)
                                .foregroundColor(.black)
                                .lineLimit(2)
                        }
                        
                        Text(polaroid.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, polaroid.frameWidth)
                    .padding(.vertical, 10)
                }
                .frame(height: 60)
            }
        }
        .frame(width: polaroid.size.width, height: polaroid.size.height)
        .rotationEffect(.degrees(polaroid.rotation))
    }
}
