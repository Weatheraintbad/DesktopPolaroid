import SwiftUI

struct HelpView: View {
    @State private var showingTutorial = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // 标题
                VStack(alignment: .leading, spacing: 5) {
                    Text("帮助与支持")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("了解如何使用拍立得桌面贴的所有功能")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // 快速指南
                VStack(alignment: .leading, spacing: 20) {
                    Text("快速指南")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    GuideStep(
                        number: 1,
                        title: "创建拍立得",
                        description: "在\"创建拍立得\"页面选择照片，自定义相框样式，然后点击创建按钮"
                    )
                    
                    GuideStep(
                        number: 2,
                        title: "管理拍立得",
                        description: "在\"管理拍立得\"页面查看所有创建的拍立得，可以编辑、删除或重新定位"
                    )
                    
                    GuideStep(
                        number: 3,
                        title: "桌面操作",
                        description: "在桌面上拖动拍立得来移动位置，使用双指旋转来调整角度"
                    )
                    
                    GuideStep(
                        number: 4,
                        title: "编辑拍立得",
                        description: "双击桌面上的拍立得或在管理页面点击编辑按钮来修改拍立得设置"
                    )
                }
                
                Divider()
                
                // 常见问题
                VStack(alignment: .leading, spacing: 20) {
                    Text("常见问题")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    FAQItem(
                        question: "拍立得贴纸会影响我的桌面性能吗？",
                        answer: "不会。拍立得贴纸使用优化的渲染技术，对系统性能影响极小。"
                    )
                    
                    FAQItem(
                        question: "如何删除桌面上的拍立得？",
                        answer: "点击拍立得右上角的X按钮，或右键点击选择删除选项。"
                    )
                    
                    FAQItem(
                        question: "拍立得的数据保存在哪里？",
                        answer: "所有拍立得数据都保存在本地，支持备份和恢复。"
                    )
                    
                    FAQItem(
                        question: "支持哪些图片格式？",
                        answer: "支持JPEG、PNG、HEIC、GIF和TIFF格式。"
                    )
                }
                
                Divider()
                
                // 联系支持
                VStack(alignment: .leading, spacing: 20) {
                    Text("更多帮助")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("查看完整教程")
                                .font(.headline)
                            Spacer()
                            Button("打开教程") {
                                showingTutorial = true
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("联系支持团队")
                                .font(.headline)
                            Spacer()
                            Link("发送邮件", destination: URL(string: "mailto:support@polaroiddesktop.com")!)
                                .buttonStyle(.bordered)
                        }
                        
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("访问官方网站")
                                .font(.headline)
                            Spacer()
                            Link("打开网站", destination: URL(string: "https://example.com")!)
                                .buttonStyle(.bordered)
                        }
                    }
                }
                
                // 按钮
                HStack {
                    Spacer()
                    Button(action: { showingTutorial = true }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("观看视频教程")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
                .padding(.vertical, 40)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showingTutorial) {
            TutorialView()
        }
    }
}

struct GuideStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Circle()
                .fill(Color.blue)
                .frame(width: 30, height: 30)
                .overlay(
                    Text("\(number)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.headline)
            Text(answer)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.leading, 10)
        }
    }
}

struct TutorialView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("视频教程")
                .font(.title)
                .fontWeight(.bold)
            
            // 这里可以放置视频播放器或教程内容
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 500, height: 300)
                .overlay(
                    VStack(spacing: 15) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        Text("教程视频加载中...")
                            .font(.title2)
                    }
                )
            
            Text("学习如何使用拍立得桌面贴的所有功能")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("关闭") {
                NSApp.keyWindow?.close()
            }
            .buttonStyle(.bordered)
            .padding(.top, 20)
        }
        .padding()
        .frame(width: 600, height: 500)
    }
}
