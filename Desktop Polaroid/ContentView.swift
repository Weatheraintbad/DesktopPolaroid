import SwiftUI

struct ContentView: View {
    @EnvironmentObject var polaroidManager: PolaroidManager
    @AppStorage("hasShownWelcome") private var hasShownWelcome = false
    @State private var showingWelcomeModal = false
    @State private var selectedTab: SidebarTab = .create
    
    enum SidebarTab: String, CaseIterable {
        case create = "创建拍立得"
        case manage = "管理拍立得"
        case settings = "设置"
        case help = "帮助"
        
        var icon: String {
            switch self {
            case .create: return "plus.circle.fill"
            case .manage: return "photo.stack"
            case .settings: return "gear"
            case .help: return "questionmark.circle"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            // 左侧侧边栏
            List(selection: $selectedTab) {
                ForEach(SidebarTab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .font(.headline)
                        .tag(tab)
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200, idealWidth: 220, maxWidth: 250)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: toggleSidebar) {
                        Image(systemName: "sidebar.left")
                    }
                }
            }
            
            // 右侧内容区域
            Group {
                switch selectedTab {
                case .create:
                    CreatePolaroidView()
                case .manage:
                    ManagePolaroidsView()
                case .settings:
                    SettingsView()
                case .help:
                    HelpView()
                }
            }
            .frame(minWidth: 600, minHeight: 600)
        }
        .onAppear {
            // 首次启动显示欢迎弹窗
            if !hasShownWelcome {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingWelcomeModal = true
                }
            }
        }
        .sheet(isPresented: $showingWelcomeModal) {
            WelcomeModalView()
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?
            .tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

struct WelcomeModalView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            // 标题
            VStack(spacing: 10) {
                Image(systemName: "camera.on.rectangle")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("欢迎使用拍立得桌面贴")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("将您最爱的照片变成桌面上的精美拍立得贴纸")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            // 功能介绍
            VStack(alignment: .leading, spacing: 25) {
                FeatureRow(
                    icon: "photo.fill",
                    title: "添加照片",
                    description: "从您的电脑中选择照片，创建个性化的拍立得贴纸"
                )
                
                FeatureRow(
                    icon: "paintbrush.fill",
                    title: "自定义相框",
                    description: "调整相框颜色、宽度和阴影效果，打造独特外观"
                )
                
                FeatureRow(
                    icon: "text.bubble.fill",
                    title: "添加标注",
                    description: "为每张照片添加标题和日期，记录美好时刻"
                )
                
                FeatureRow(
                    icon: "rectangle.and.pencil.and.ellipsis",
                    title: "桌面交互",
                    description: "在桌面上自由拖动、旋转贴纸，双击可重新编辑"
                )
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // 开始按钮
            Button(action: { dismiss() }) {
                Text("开始使用")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(width: 200, height: 50)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 40)
        }
        .frame(width: 600, height: 700)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}
