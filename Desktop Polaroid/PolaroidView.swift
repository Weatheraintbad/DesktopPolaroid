import SwiftUI
import UniformTypeIdentifiers

struct PolaroidView: View {
    @EnvironmentObject var polaroidManager: PolaroidManager
    @State private var currentRotation: Double = 0
    @State private var isDragging = false
    @State private var isRotating = false
    @State private var showingEditView = false
    @State private var polaroid: Polaroid

    // 添加拖拽状态
    @State private var dragStartWindowPosition: CGPoint = .zero
    @State private var dragStartGlobalMouseLocation: CGPoint = .zero // 记录全局初始鼠标位置
    @State private var rotateStartAngle: Double = 0
    @State private var rotateStartPoint: CGPoint = .zero

    // 添加悬停状态
    @State private var isHovering = false

    // 当前窗口引用
    @State private var currentWindow: NSWindow?
    
    init(polaroid: Polaroid? = nil) {
        _polaroid = State(initialValue: polaroid ?? Polaroid())
    }
    
    var body: some View {
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
        .gesture(
            DragGesture(minimumDistance: 0) // 最小距离设为0，确保拖拽立即响应
                .onChanged { value in
                    if !isDragging && !isRotating {
                        isDragging = true
                        // 记录拖拽开始时的窗口位置和全局鼠标位置（不受窗口移动影响）
                        if let window = currentWindow {
                            dragStartWindowPosition = window.frame.origin
                        }
                        dragStartGlobalMouseLocation = NSEvent.mouseLocation // 全局鼠标坐标，原点在屏幕左下角
                    }

                    // 直接用全局鼠标位置计算偏移，彻底解决抖动问题
                    if let window = currentWindow {
                        let currentGlobalMouse = NSEvent.mouseLocation
                        let offsetX = currentGlobalMouse.x - dragStartGlobalMouseLocation.x
                        let offsetY = currentGlobalMouse.y - dragStartGlobalMouseLocation.y

                        var newOrigin = dragStartWindowPosition
                        newOrigin.x += offsetX
                        newOrigin.y += offsetY // 全局坐标和窗口坐标都是左下角为原点，不需要转换

                        window.setFrameOrigin(newOrigin)
                    }
                }
                .onEnded { value in
                    if isDragging {
                        // 保存新位置到数据模型
                        if let window = currentWindow {
                            let newPosition = window.frame.origin

                            // 确保位置在屏幕内
                            let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
                            let boundedX = min(max(newPosition.x, screenRect.minX), screenRect.maxX - polaroid.size.width)
                            let boundedY = min(max(newPosition.y, screenRect.minY), screenRect.maxY - polaroid.size.height)

                            // 更新窗口位置和数据模型
                            window.setFrameOrigin(CGPoint(x: boundedX, y: boundedY))
                            polaroid.position = CGPoint(x: boundedX, y: boundedY)
                            polaroidManager.updatePolaroid(polaroid)
                        }

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

            Button("从桌面撤下") {
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
        .frame(width: polaroid.size.width, height: polaroid.size.height)
        // 可靠地获取当前视图所在的窗口
        .background(WindowAccessor(window: $currentWindow))
    }
    
    private func closePolaroid() {
        // 只关闭窗口，不删除数据
        polaroidManager.closeWindowForPolaroid(polaroid.id)
    }
}

// 辅助类：获取当前视图所在的NSWindow
struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.window = view.window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
