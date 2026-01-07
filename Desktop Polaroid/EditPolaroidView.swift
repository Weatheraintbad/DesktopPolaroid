import SwiftUI
import UniformTypeIdentifiers

struct EditPolaroidView: View {
    @EnvironmentObject var polaroidManager: PolaroidManager
    @Environment(\.dismiss) var dismiss
    @Binding var polaroid: Polaroid
    @State private var showingImagePicker = false
    
    // 为每个属性创建独立的 State
    @State private var tempTitle: String
    @State private var tempDate: Date
    @State private var tempFrameColor: Color
    @State private var tempFrameWidth: CGFloat
    @State private var tempShadowRadius: CGFloat
    @State private var tempRotation: Double
    @State private var tempSize: CGSize
    @State private var tempImageData: Data?
    
    // 简化初始化
    init(polaroid: Binding<Polaroid>) {
        self._polaroid = polaroid
        
        let currentPolaroid = polaroid.wrappedValue
        
        // 分别初始化每个状态
        self._tempTitle = State(initialValue: currentPolaroid.title)
        self._tempDate = State(initialValue: currentPolaroid.date)
        self._tempFrameColor = State(initialValue: currentPolaroid.frameColor)
        self._tempFrameWidth = State(initialValue: currentPolaroid.frameWidth)
        self._tempShadowRadius = State(initialValue: currentPolaroid.shadowRadius)
        self._tempRotation = State(initialValue: currentPolaroid.rotation)
        self._tempSize = State(initialValue: currentPolaroid.size)
        self._tempImageData = State(initialValue: currentPolaroid.imageData)
    }
    
    // 预览用的 Polaroid
    private var previewPolaroid: Polaroid {
        Polaroid(
            id: polaroid.id,
            imageData: tempImageData,
            frameColor: tempFrameColor,
            frameWidth: tempFrameWidth,
            shadowRadius: tempShadowRadius,
            rotation: tempRotation,
            position: polaroid.position,
            size: tempSize,
            title: tempTitle,
            date: tempDate,
            isPinned: polaroid.isPinned
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            HStack {
                Button("取消") {
                    dismiss()
                }
                
                Spacer()
                
                Text("编辑拍立得")
                    .font(.headline)
                
                Spacer()
                
                Button("保存") {
                    saveChanges()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            HStack(spacing: 0) {
                // 左侧：设置面板
                ScrollView {
                    settingsPanel
                        .padding(.horizontal)
                }
                .frame(width: 350)
                .background(Color.gray.opacity(0.05))
                
                // 右侧：实时预览
                previewPanel
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(width: 800, height: 600)
        .fileImporter(
            isPresented: $showingImagePicker,
            allowedContentTypes: [UTType.image],
            allowsMultipleSelection: false
        ) { result in
            handleImagePickerResult(result)
        }
    }
    
    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 图片设置
            Group {
                Text("图片")
                    .font(.headline)
                
                Button("更换图片") {
                    showingImagePicker = true
                }
                .buttonStyle(.bordered)
            }
            
            Divider()
            
            // 相框颜色
            Group {
                Text("相框颜色")
                    .font(.headline)
                
                HStack {
                    ForEach([Color.white, Color.yellow, Color.pink, Color.blue, Color.green], id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary.opacity(0.3),
                                            lineWidth: color == tempFrameColor ? 3 : 0)
                            )
                            .onTapGesture {
                                tempFrameColor = color
                            }
                    }
                    
                    Spacer()
                    
                    ColorPicker("", selection: $tempFrameColor)
                        .labelsHidden()
                }
            }
            
            Divider()
            
            // 尺寸设置
            Group {
                Text("相框尺寸")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("宽度: \(Int(tempSize.width))px")
                    Slider(value: $tempSize.width, in: 200...500, step: 10)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("高度: \(Int(tempSize.height))px")
                    Slider(value: $tempSize.height, in: 250...600, step: 10)
                }
            }
            
            Divider()
            
            // 效果设置
            Group {
                Text("效果设置")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("边框宽度: \(Int(tempFrameWidth))px")
                    Slider(value: $tempFrameWidth, in: 10...50, step: 5)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("阴影大小: \(Int(tempShadowRadius))px")
                    Slider(value: $tempShadowRadius, in: 0...20, step: 1)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("旋转角度: \(Int(tempRotation))°")
                    Slider(value: $tempRotation, in: -180...180, step: 1)
                }
            }
            
            Divider()
            
            // 照片信息
            Group {
                Text("照片信息")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("标题")
                    TextField("输入标题...", text: $tempTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("日期")
                    DatePicker("", selection: $tempDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }
            .padding(.bottom)
        }
        .padding(.top)
    }
    
    private var previewPanel: some View {
        VStack {
            Text("实时预览")
                .font(.headline)
                .padding(.top)
            
            // 预览区域
            previewPolaroidView
                .frame(width: 300, height: 350)
                .padding(.top, 20)
            
            Spacer()
            
            // 预览说明
            VStack(alignment: .leading, spacing: 5) {
                Text("说明")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("左侧的修改会实时反映在右侧的预览中。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    private var previewPolaroidView: some View {
        ZStack {
            // 相框
            RoundedRectangle(cornerRadius: 2)
                .fill(tempFrameColor)
                .shadow(radius: tempShadowRadius)
            
            VStack(spacing: 0) {
                // 图片区域
                if let imageData = tempImageData, let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: tempSize.width - tempFrameWidth * 2,
                               height: tempSize.height - tempFrameWidth * 2 - 60)
                        .clipped()
                        .padding(tempFrameWidth)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: tempSize.width - tempFrameWidth * 2,
                               height: tempSize.height - tempFrameWidth * 2 - 60)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                        .padding(tempFrameWidth)
                }
                
                // 底部区域
                ZStack {
                    Rectangle()
                        .fill(tempFrameColor)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        if !tempTitle.isEmpty {
                            Text(tempTitle)
                                .font(.headline)
                                .foregroundColor(.black)
                                .lineLimit(2)
                        }
                        
                        Text(tempDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, tempFrameWidth)
                    .padding(.vertical, 10)
                }
                .frame(height: 60)
            }
        }
        .frame(width: tempSize.width, height: tempSize.height)
        .rotationEffect(.degrees(tempRotation))
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
                    // 转换为PNG数据
                    if let tiffData = image.tiffRepresentation,
                       let bitmapImage = NSBitmapImageRep(data: tiffData),
                       let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                        tempImageData = pngData
                    }
                }
            }
        } catch {
            print("Error selecting image: \(error)")
        }
    }
    
    private func saveChanges() {
        // 创建更新后的拍立得
        let updatedPolaroid = Polaroid(
            id: polaroid.id,
            imageData: tempImageData,
            frameColor: tempFrameColor,
            frameWidth: tempFrameWidth,
            shadowRadius: tempShadowRadius,
            rotation: tempRotation,
            position: polaroid.position,
            size: tempSize,
            title: tempTitle,
            date: tempDate,
            isPinned: polaroid.isPinned
        )
        
        // 更新绑定值
        polaroid = updatedPolaroid
        polaroidManager.updatePolaroid(updatedPolaroid)
        
        dismiss()
    }
}
