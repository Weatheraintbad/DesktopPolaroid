import SwiftUI
import UniformTypeIdentifiers

struct PolaroidView: View {
    @EnvironmentObject var polaroidManager: PolaroidManager
    @State private var offset: CGSize = .zero
    @State private var currentRotation: Double = 0
    @State private var isDragging = false
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    @State private var polaroid: Polaroid
    
    // 添加拖拽状态
    @State private var dragStartPosition: CGPoint = .zero
    
    init(polaroid: Polaroid? = nil) {
        _polaroid = State(initialValue: polaroid ?? Polaroid())
    }
    
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
            
            // 控制按钮 - 悬停时显示
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
                        
                        // 删除按钮
                        Button(action: { showingDeleteAlert = true }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
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
        .frame(width: polaroid.size.width, height: polaroid.size.height)
        .rotationEffect(.degrees(polaroid.rotation + currentRotation))
        .offset(offset)
        .position(polaroid.position)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        dragStartPosition = polaroid.position
                    }
                    offset = value.translation
                }
                .onEnded { value in
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
        )
        .gesture(
            RotationGesture()
                .onChanged { angle in
                    currentRotation = angle.degrees
                }
                .onEnded { angle in
                    polaroid.rotation += angle.degrees
                    currentRotation = 0
                    polaroidManager.updatePolaroid(polaroid)
                }
        )
        .onTapGesture(count: 2) {
            showingEditView = true
        }
        .contextMenu {
            Button("编辑") {
                showingEditView = true
            }
            
            Divider()
            
            Button("删除", role: .destructive) {
                showingDeleteAlert = true
            }
        }
        .alert("删除拍立得", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                polaroidManager.removePolaroid(polaroid)
            }
        } message: {
            Text("确定要删除这个拍立得吗？删除后无法恢复。")
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
}
