import SwiftUI

struct ContentView: View {
    @EnvironmentObject var polaroidManager: PolaroidManager
    @State private var showingWelcomeModal = false  // 控制是否显示欢迎页面
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
                    SettingsView()  // 使用恢复的设置界面
                case .help:
                    HelpView()      // 使用帮助视图
                }
            }
            .frame(minWidth: 700, minHeight: 600)
        }
        .onAppear {
            // 检查用户是否选择了"不再显示"
            let skipWelcome = UserDefaults.standard.bool(forKey: "skipWelcomeScreen")
            
            if !skipWelcome {
                // 用户没有选择跳过，显示欢迎页面
                // 使用主队列确保在视图加载完成后显示
                DispatchQueue.main.async {
                    showingWelcomeModal = true
                }
            }
        }        .sheet(isPresented: $showingWelcomeModal) {
            WelcomeModalView(isPresented: $showingWelcomeModal)
        }
        .frame(minWidth: 1000, minHeight: 700)
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?
            .tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}
