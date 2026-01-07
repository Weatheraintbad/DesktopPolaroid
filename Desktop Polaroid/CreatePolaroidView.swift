import SwiftUI
import UniformTypeIdentifiers

struct CreatePolaroidView: View {
    @EnvironmentObject var polaroidManager: PolaroidManager
    @State private var showingImagePicker = false
    @State private var selectedImage: NSImage?
    @State private var newPolaroid = Polaroid()
    
    var body: some View {
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
                                    .frame(width: 300, height: 300)
                                    .clipped()
                                    .cornerRadius(12)
                                    .shadow(radius: 5)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 300, height: 300)
                                    .overlay(
                                        VStack(spacing: 15) {
                                            Image(systemName: "photo.on.rectangle.angled")
                                                .font(.system(size: 60))
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
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary.opacity(0.3), lineWidth: color == newPolaroid.frameColor ? 3 : 0)
                                    )
                                    .onTapGesture {
                                        newPolaroid.frameColor = color
                                    }
                                    .padding(5)
                            }
                            
                            ColorPicker("自定义颜色", selection: $newPolaroid.frameColor, supportsOpacity: false)
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
                                .frame(width: 300)
                        }
                        
                        HStack {
                            Text("高度: \(Int(newPolaroid.size.height))px")
                            Slider(value: $newPolaroid.size.height, in: 250...600, step: 10)
                                .frame(width: 300)
                        }
                    }
                    
                    // 其他设置
                    VStack(alignment: .leading, spacing: 15) {
                        Text("效果设置")
                            .font(.headline)
                        
                        HStack {
                            Text("边框宽度: \(Int(newPolaroid.frameWidth))px")
                            Slider(value: $newPolaroid.frameWidth, in: 10...50, step: 5)
                                .frame(width: 300)
                        }
                        
                        HStack {
                            Text("阴影大小: \(Int(newPolaroid.shadowRadius))px")
                            Slider(value: $newPolaroid.shadowRadius, in: 0...20, step: 1)
                                .frame(width: 300)
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
                                .frame(width: 400)
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
                        .frame(width: 300, height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(selectedImage == nil)
                    Spacer()
                }
                .padding(.vertical, 30)
            }
            .padding(.horizontal, 40)
        }
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
        
        // 随机设置初始位置
        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 800, height: 600)
        newPolaroid.position = CGPoint(
            x: CGFloat.random(in: 50...screenSize.width - newPolaroid.size.width),
            y: CGFloat.random(in: 50...screenSize.height - newPolaroid.size.height)
        )
        
        // 添加随机旋转
        newPolaroid.rotation = Double.random(in: -5...5)
        
        // 添加到管理器 - 这会自动创建窗口
        polaroidManager.addPolaroid(newPolaroid)
        
        // 重置表单
        selectedImage = nil
        newPolaroid = Polaroid()
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
                    // 转换为PNG数据
                    if let tiffData = image.tiffRepresentation,
                       let bitmapImage = NSBitmapImageRep(data: tiffData),
                       let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                        newPolaroid.imageData = pngData
                    }
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
                            // 转换为PNG数据
                            if let tiffData = nsImage.tiffRepresentation,
                               let bitmapImage = NSBitmapImageRep(data: tiffData),
                               let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                                newPolaroid.imageData = pngData
                            }
                        }
                    }
                }
            }
        }
    }
}
