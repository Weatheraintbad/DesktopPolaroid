import SwiftUI

struct WelcomeModalView: View {
    @Binding var isPresented: Bool
    @State private var dontShowAgain = false
    
    init(isPresented: Binding<Bool>? = nil) {
        self._isPresented = isPresented ?? .constant(true)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题区域 - 向上移动
            VStack(spacing: 10) {
                Image(systemName: "camera.on.rectangle")
                    .font(.system(size: 70))
                    .foregroundColor(.blue)
                    .padding(.bottom, 5)
                
                Text("欢迎使用拍立得桌面贴")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("将您最爱的照片变成桌面上的精美拍立得贴纸")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 50)  // 减少顶部间距
            .padding(.bottom, 40)
            
            // 功能介绍区域 - 使用更紧凑的布局
            VStack(alignment: .leading, spacing: 20) {
                WelcomeFeatureRow(
                    icon: "photo.fill",
                    title: "添加照片",
                    description: "从您的电脑中选择照片，创建个性化的拍立得贴纸"
                )
                
                WelcomeFeatureRow(
                    icon: "paintbrush.fill",
                    title: "自定义相框",
                    description: "调整相框颜色、宽度和阴影效果，打造独特外观"
                )
                
                WelcomeFeatureRow(
                    icon: "text.bubble.fill",
                    title: "添加标注",
                    description: "为每张照片添加标题和日期，记录美好时刻"
                )
                
                WelcomeFeatureRow(
                    icon: "rectangle.and.pencil.and.ellipsis",
                    title: "桌面交互",
                    description: "在桌面上自由拖动、旋转贴纸，双击可重新编辑"
                )
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
            
            Spacer()
            
            // 底部按钮区域
            VStack(spacing: 20) {
                // 开始使用按钮
                Button(action: {
                    isPresented = false
                }) {
                    Text("开始使用")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(width: 250)
                
                // 不再显示选项 - 放在按钮下方
                HStack(spacing: 10) {
                    Toggle("", isOn: $dontShowAgain)
                        .toggleStyle(.checkbox)
                        .scaleEffect(0.9)
                    
                    Text("不再显示此欢迎页面")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .onTapGesture {
                            dontShowAgain.toggle()
                        }
                }
                .padding(.top, 5)
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 40)
        }
        .frame(width: 600, height: 700)
        .onAppear {
            // 检查是否设置过不再显示
            dontShowAgain = UserDefaults.standard.bool(forKey: "skipWelcomeScreen")
        }
        .onChange(of: dontShowAgain) { oldValue, newValue in
            UserDefaults.standard.set(newValue, forKey: "skipWelcomeScreen")
        }
        .onDisappear {
            // 如果用户选择了"不再显示"，保存设置
            if dontShowAgain {
                UserDefaults.standard.set(true, forKey: "skipWelcomeScreen")
            }
        }
    }
}

struct WelcomeFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30, height: 30)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
