import SwiftUI

struct ManagePolaroidsView: View {
    @EnvironmentObject var polaroidManager: PolaroidManager
    @State private var searchText = ""
    
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
                        GridItem(.adaptive(minimum: 300, maximum: 350), spacing: 20)
                    ], spacing: 20) {
                        ForEach(filteredPolaroids) { polaroid in
                            PolaroidCardView(polaroid: polaroid)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 20)
                }
            }
        }
    }
}

struct PolaroidCardView: View {
    @EnvironmentObject var polaroidManager: PolaroidManager
    let polaroid: Polaroid
    @State private var showingDeleteAlert = false
    @State private var showingEditView = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 图片预览
            ZStack {
                if let nsImage = polaroid.nsImage {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                }
                
                // 顶部操作栏
                VStack {
                    HStack {
                        Spacer()
                        Menu {
                            Button("编辑") {
                                showingEditView = true
                            }
                            
                            Button("定位到桌面", action: locateOnDesktop)
                            
                            Divider()
                            
                            Button("删除", role: .destructive) {
                                showingDeleteAlert = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                    }
                    Spacer()
                }
            }
            .frame(height: 200)
            
            // 信息区域
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if !polaroid.title.isEmpty {
                        Text(polaroid.title)
                            .font(.headline)
                            .lineLimit(1)
                    } else {
                        Text("无标题")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 预览颜色
                    Circle()
                        .fill(polaroid.frameColor)
                        .frame(width: 12, height: 12)
                }
                
                Text("创建于 \(polaroid.date, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("尺寸: \(Int(polaroid.size.width))×\(Int(polaroid.size.height))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("位置: (\(Int(polaroid.position.x)), \(Int(polaroid.position.y)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(15)
            .background(Color.gray.opacity(0.05))
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .alert("删除拍立得", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                polaroidManager.removePolaroid(polaroid)
            }
        } message: {
            Text("确定要删除这个拍立得吗？")
        }
        .sheet(isPresented: $showingEditView) {
            // 直接创建绑定
            let binding = Binding(
                get: { polaroid },
                set: { newValue in
                    // 更新管理器中的拍立得
                    polaroidManager.updatePolaroid(newValue)
                }
            )
            EditPolaroidView(polaroid: binding)
                .environmentObject(polaroidManager)
        }
    }
    
    private func locateOnDesktop() {
        // 这里可以实现在桌面上找到并聚焦到该拍立得
        // 目前先留空，后续可以添加窗口聚焦功能
    }
}
