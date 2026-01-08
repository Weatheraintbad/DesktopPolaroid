import SwiftUI

struct ManagePolaroidsView: View {
    @EnvironmentObject var polaroidManager: PolaroidManager
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    @State private var polaroidToDelete: Polaroid?
    @State private var showingReopenAlert = false
    @State private var polaroidToReopen: Polaroid?
    
    var filteredPolaroids: [Polaroid] {
        if searchText.isEmpty {
            return polaroidManager.polaroids
        } else {
            return polaroidManager.polaroids.filter { polaroid in
                polaroid.title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            VStack(alignment: .leading, spacing: 5) {
                Text("管理拍立得")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("查看和管理您创建的所有拍立得贴纸")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 30)
            .padding(.top, 20)
            .padding(.bottom, 15)
            
            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("搜索拍立得标题...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
            
            // 拍立得列表
            ScrollView {
                if filteredPolaroids.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("还没有创建任何拍立得")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("点击左侧的\"创建拍立得\"开始添加照片")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 100)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 320, maximum: 400), spacing: 20)
                    ], spacing: 20) {
                        ForEach(filteredPolaroids) { polaroid in
                            PolaroidCardView(
                                polaroid: polaroid,
                                onDelete: { deletePolaroid($0) },
                                onReopen: { reopenPolaroid($0) }
                            )
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 20)
                }
            }
        }
        .alert("删除拍立得", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let polaroid = polaroidToDelete {
                    polaroidManager.removePolaroid(polaroid)
                }
            }
        } message: {
            Text("确定要永久删除这个拍立得吗？此操作无法撤销。")
        }
        .alert("重新打开拍立得", isPresented: $showingReopenAlert) {
            Button("取消", role: .cancel) { }
            Button("打开", role: .none) {
                if let polaroid = polaroidToReopen {
                    polaroidManager.reopenPolaroid(polaroid)
                }
            }
        } message: {
            Text("确定要在桌面上重新打开这个拍立得吗？")
        }
    }
    
    func deletePolaroid(_ polaroid: Polaroid) {
        polaroidToDelete = polaroid
        showingDeleteAlert = true
    }
    
    func reopenPolaroid(_ polaroid: Polaroid) {
        polaroidToReopen = polaroid
        showingReopenAlert = true
    }
}

struct PolaroidCardView: View {
    @EnvironmentObject var polaroidManager: PolaroidManager
    let polaroid: Polaroid
    let onDelete: (Polaroid) -> Void
    let onReopen: (Polaroid) -> Void
    @State private var showingEditView = false
    @State private var isHovering = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // 照片预览区域（带悬停效果）
            ZStack {
                // 预览组件
                ManagePolaroidPreviewView(polaroid: polaroid)
                    .frame(width: 180, height: 220)
                    .rotationEffect(.degrees(polaroid.rotation * 0.2))
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                
                // 悬停时显示的按钮
                if isHovering {
                    VStack {
                        Spacer()
                        
                        HStack(spacing: 10) {
                            if polaroidManager.isWindowOpen(for: polaroid.id) {
                                Button("已贴在桌面") {
                                    // 可以添加聚焦到窗口的功能
                                }
                                .buttonStyle(.bordered)
                                .font(.caption)
                                .foregroundColor(.green)
                                .disabled(true)
                            } else {
                                Button("贴到桌面") {
                                    polaroidManager.reopenPolaroid(polaroid)
                                }
                                .buttonStyle(.bordered)
                                .font(.caption)
                            }
                            
                            Button("删除") {
                                onDelete(polaroid)
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                            .font(.caption)
                        }
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .padding(.bottom, 10)
                    }
                    .transition(.opacity)
                }
            }
            .frame(width: 180, height: 220)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
            
            // 信息区域（放在预览组件右侧）
            VStack(alignment: .leading, spacing: 12) {
                // 标题和窗口状态
                HStack {
                    if !polaroid.title.isEmpty {
                        Text(polaroid.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                    } else {
                        Text("无标题")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 窗口状态指示器
                    if polaroidManager.isWindowOpen(for: polaroid.id) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("已打开")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // 元信息
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("创建于 \(polaroid.date, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "ruler")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("尺寸: \(Int(polaroid.size.width))×\(Int(polaroid.size.height))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "rotate.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("旋转: \(Int(polaroid.rotation))°")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
                
                Spacer()
                
                // 编辑按钮
                Button {
                    showingEditView = true
                } label: {
                    HStack {
                        Image(systemName: "pencil")
                        Text("编辑拍立得")
                    }
                    .font(.body)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.top, 10)
            }
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
        .contentShape(Rectangle())
        .sheet(isPresented: $showingEditView) {
            EditPolaroidView(polaroid: Binding(
                get: { polaroid },
                set: { newValue in
                    // 更新管理器中的拍立得
                    polaroidManager.updatePolaroid(newValue)
                }
            ))
            .environmentObject(polaroidManager)
        }
    }
}

// 管理界面的预览组件 - 使用 CreatePolaroidPreviewView
struct ManagePolaroidPreviewView: View {
    let polaroid: Polaroid
    @State private var previewScale: CGFloat = 0.3
    
    var body: some View {
        ZStack {
            // 白色背景作为拍立得照片的底
            Rectangle()
                .fill(Color.white)
                .frame(width: 280 * previewScale, height: 350 * previewScale)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            
            // 直接使用 CreatePolaroidPreviewView
            CreatePolaroidPreviewView(polaroid: polaroid)
                .scaleEffect(previewScale)
                .frame(width: 280 * previewScale, height: 350 * previewScale)
        }
        .frame(width: 180, height: 220)
        .onAppear {
            // 根据拍立得尺寸调整预览比例
            let widthRatio = 160 / polaroid.size.width
            let heightRatio = 200 / polaroid.size.height
            previewScale = min(widthRatio, heightRatio) * 0.9
        }
    }
}
