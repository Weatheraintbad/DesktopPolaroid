import SwiftUI

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // 预览主内容视图
        ContentView()
            .environmentObject(PolaroidManager())
            .frame(width: 800, height: 600)
        
        // 预览创建拍立得视图
        CreatePolaroidView()
            .environmentObject(PolaroidManager())
            .frame(width: 800, height: 600)
            .previewDisplayName("创建拍立得")
        
        // 预览管理拍立得视图
        ManagePolaroidsView()
            .environmentObject(PolaroidManager())
            .frame(width: 800, height: 600)
            .previewDisplayName("管理拍立得")
        
        // 预览设置视图
        SettingsView()
            .frame(width: 800, height: 600)
            .previewDisplayName("设置")
        
        // 预览帮助视图
        HelpView()
            .frame(width: 800, height: 600)
            .previewDisplayName("帮助")
        
        // 预览单个拍立得视图
        PolaroidView()
            .environmentObject(PolaroidManager())
            .frame(width: 300, height: 350)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("拍立得卡片")
        
        // 预览编辑拍立得视图
        EditPolaroidView(polaroid: .constant(Polaroid()))
            .environmentObject(PolaroidManager())
            .frame(width: 600, height: 700)
            .previewDisplayName("编辑拍立得")
    }
}
