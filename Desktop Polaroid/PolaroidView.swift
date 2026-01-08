import SwiftUI
import UniformTypeIdentifiers

struct PolaroidView: View {
    @EnvironmentObject var polaroidManager: PolaroidManager
    @State private var offset: CGSize = .zero
    @State private var currentRotation: Double = 0
    @State private var isDragging = false
    @State private var isRotating = false
    @State private var showingEditView = false
    @State private var polaroid: Polaroid
    
    // 添加拖拽状态
    @State private var dragStartPosition: CGPoint = .zero
    @State private var rotateStartAngle: Double = 0
    @State private var rotateStartPoint: CGPoint = .zero
    
    // 添加悬停状态
    @State private var isHovering = false
    
    init(polaroid: Polaroid? = nil) {
        _polaroid = State(initialValue: polaroid ?? Polaroid())
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 相框背景
                RoundedRectangle(cornerRadius: 2)
                    .fill(polaroid.frameColor)
                    .shadow(radius: polaroid.shadowRadius)
                    .frame(width: polaroid.size.width, height: polaroid.size.height)
                
                // 内容区域
                VStack(spacing: 0) {
                    // 图片区域 - 使用 overlay 避免裁剪
                    if let nsImage = polaroid.nsImage {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: polaroid.size.width - polaroid.frameWidth * 2,
                                   height: polaroid.size.height - polaroid.frameWidth * 2 - 60)
                            .clipped()
                            .overlay(
                                RoundedRectangle(cornerRadius: 0)
                                    .stroke(Color.clear, lineWidth: 0)
                            )
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
                    
                    // 底部区域（用于写字）
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
                .frame(width: polaroid.size.width, height: polaroid.size.height)
                
                // 控制按钮 - 悬停时显示
                if isHovering {
                    VStack {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                // 编辑按钮
                                Button(action: { showingEditView = true }) {
                                    Image(systemName: "pencil.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.title2)
                                        .background(Circle().fill(Color.white).frame(width: 30, height: 30))
                                }
                                .buttonStyle(.plain)
                                
                                // 关闭按钮（只关闭窗口，不删除数据）
                                Button(action: { closePolaroid() }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.orange)
                                        .font(.title2)
                                        .background(Circle().fill(Color.white).frame(width: 30, height: 30))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(8)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(15)
                            .padding(10)
                        }
                        Spacer()
                    }
                }
                
                // 旋转控制点（左下角）- 只在悬停时显示
                if isHovering {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.8))
                            .frame(width: 24, height: 24)
                            .shadow(radius: 2)
                        
                        Image(systemName: "arrow.2.circlepath")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .position(x: 20, y: polaroid.size.height - 20)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if !isRotating {
                                    isRotating = true
                                    rotateStartAngle = polaroid.rotation
                                    let center = CGPoint(x: polaroid.size.width / 2, y: polaroid.size.height / 2)
                                    rotateStartPoint = CGPoint(x: value.startLocation.x - center.x,
                                                              y: center.y - value.startLocation.y)
                                }
                                
                                let center = CGPoint(x: polaroid.size.width / 2, y: polaroid.size.height / 2)
                                let currentPoint = CGPoint(x: value.location.x - center.x,
                                                          y: center.y - value.location.y)
                                
                                let startAngle = atan2(rotateStartPoint.y, rotateStartPoint.x)
                                let currentAngle = atan2(currentPoint.y, currentPoint.x)
                                let angleDifference = (currentAngle - startAngle) * 180 / .pi
                                
                                polaroid.rotation = rotateStartAngle + angleDifference
                            }
                            .onEnded { _ in
                                isRotating = false
                                polaroidManager.updatePolaroid(polaroid)
                            }
                    )
                }
            }
            .frame(width: polaroid.size.width, height: polaroid.size.height)
            .rotationEffect(.degrees(polaroid.rotation))
            .offset(offset)
            .position(polaroid.position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isDragging && !isRotating {
                            isDragging = true
                            dragStartPosition = polaroid.position
                        }
                        offset = value.translation
                    }
                    .onEnded { value in
                        if isDragging {
                            let newX = dragStartPosition.x + value.translation.width
                            let newY = dragStartPosition.y + value.translation.height
                            
                            // 确保位置在屏幕内
                            let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 800, height: 600)
                            let boundedX = min(max(newX, 0), screenSize.width - polaroid.size.width)
                            let boundedY = min(max(newY, 0), screenSize.height - polaroid.size.height)
                            
                            polaroid.position = CGPoint(x: boundedX, y: boundedY)
                            offset = .zero
                            polaroidManager.updatePolaroid(polaroid)
                            isDragging = false
                        }
                    }
            )
            .onHover { hovering in
                isHovering = hovering
            }
            .onTapGesture(count: 2) {
                showingEditView = true
            }
            .contextMenu {
                Button("编辑") {
                    showingEditView = true
                }
                
                Divider()
                
                Button("关闭窗口") {
                    closePolaroid()
                }
            }
            .sheet(isPresented: $showingEditView) {
                EditPolaroidView(polaroid: Binding(
                    get: { polaroid },
                    set: { newValue in
                        polaroid = newValue
                        polaroidManager.updatePolaroid(newValue)
                    }
                ))
                .environmentObject(polaroidManager)
            }
            .onChange(of: polaroid) { oldValue, newValue in
                polaroidManager.updatePolaroid(newValue)
            }
        }
        .frame(width: polaroid.size.width, height: polaroid.size.height)
    }
    
    private func closePolaroid() {
        // 只关闭窗口，不删除数据
        polaroidManager.closeWindowForPolaroid(polaroid.id)
    }
}
