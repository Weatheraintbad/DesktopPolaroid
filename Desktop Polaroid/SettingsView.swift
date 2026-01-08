import SwiftUI

struct SettingsView: View {
    // 使用字符串存储尺寸，然后解析
    @AppStorage("polaroidDefaultSize") private var defaultSizeString = "300,350"
    @AppStorage("polaroidDefaultColor") private var defaultColorString = "#FFFFFF" // 使用十六进制字符串存储颜色
    @AppStorage("polaroidDefaultFrameWidth") private var defaultFrameWidth: Double = 20
    @AppStorage("polaroidDefaultShadow") private var defaultShadow: Double = 10
    @AppStorage("autoSave") private var autoSave = true
    @AppStorage("showGrid") private var showGrid = false
    @AppStorage("gridSize") private var gridSize: Double = 10
    
    // 计算属性：将字符串转换为CGSize
    private var defaultSize: CGSize {
        let components = defaultSizeString.split(separator: ",")
        if components.count == 2,
           let width = Double(components[0]),
           let height = Double(components[1]) {
            return CGSize(width: width, height: height)
        }
        return CGSize(width: 300, height: 350)
    }
    
    // 计算属性：将字符串转换为Color
    private var defaultColor: Color {
        Color(hex: defaultColorString) ?? .white
    }
    
    // 将CGSize转换为字符串
    private func sizeToString(_ size: CGSize) -> String {
        return "\(Int(size.width)),\(Int(size.height))"
    }
    
    // 将Color转换为十六进制字符串
    private func colorToHex(_ color: Color) -> String {
        let nsColor = NSColor(color)
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else {
            return "#FFFFFF"
        }
        
        let red = Int(rgbColor.redComponent * 255)
        let green = Int(rgbColor.greenComponent * 255)
        let blue = Int(rgbColor.blueComponent * 255)
        
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // 标题
                VStack(alignment: .leading, spacing: 5) {
                    Text("设置")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("自定义应用程序的默认行为和外观")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // 默认设置
                VStack(alignment: .leading, spacing: 20) {
                    Text("默认拍立得设置")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    GroupBox {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("默认尺寸")
                                Spacer()
                                Text("\(Int(defaultSize.width)) × \(Int(defaultSize.height)) 像素")
                            }
                            
                            HStack {
                                Text("宽度: \(Int(defaultSize.width))px")
                                Slider(
                                    value: Binding(
                                        get: { defaultSize.width },
                                        set: { newValue in
                                            let newSize = CGSize(width: newValue, height: defaultSize.height)
                                            defaultSizeString = sizeToString(newSize)
                                        }
                                    ),
                                    in: 200...500,
                                    step: 10
                                )
                            }
                            
                            HStack {
                                Text("高度: \(Int(defaultSize.height))px")
                                Slider(
                                    value: Binding(
                                        get: { defaultSize.height },
                                        set: { newValue in
                                            let newSize = CGSize(width: defaultSize.width, height: newValue)
                                            defaultSizeString = sizeToString(newSize)
                                        }
                                    ),
                                    in: 250...600,
                                    step: 10
                                )
                            }
                        }
                        .padding(15)
                    }
                    
                    GroupBox {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("默认边框宽度")
                                Spacer()
                                Text("\(Int(defaultFrameWidth)) 像素")
                            }
                            Slider(value: $defaultFrameWidth, in: 10...50, step: 5)
                            
                            HStack {
                                Text("默认阴影大小")
                                Spacer()
                                Text("\(Int(defaultShadow)) 像素")
                            }
                            Slider(value: $defaultShadow, in: 0...20, step: 1)
                        }
                        .padding(15)
                    }
                    
                    GroupBox {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("默认边框颜色")
                            ColorPicker(
                                "选择颜色",
                                selection: Binding(
                                    get: { defaultColor },
                                    set: { newColor in
                                        defaultColorString = colorToHex(newColor)
                                    }
                                ),
                                supportsOpacity: false
                            )
                        }
                        .padding(15)
                    }
                }
                
                Divider()
                
                // 应用程序设置
                VStack(alignment: .leading, spacing: 20) {
                    Text("应用程序设置")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    GroupBox {
                        VStack(alignment: .leading, spacing: 15) {
                            Toggle("自动保存更改", isOn: $autoSave)
                                .toggleStyle(.switch)
                            
                            Toggle("显示桌面网格", isOn: $showGrid)
                                .toggleStyle(.switch)
                            
                            if showGrid {
                                HStack {
                                    Text("网格大小: \(Int(gridSize))px")
                                    Slider(value: $gridSize, in: 5...50, step: 5)
                                }
                            }
                        }
                        .padding(15)
                    }
                }
                
                Divider()
                
                // 关于
                VStack(alignment: .leading, spacing: 20) {
                    Text("关于")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    GroupBox {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "camera.on.rectangle")
                                    .font(.title)
                                Text("拍立得桌面贴")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            
                            Text("版本 1.0.0")
                                .foregroundColor(.secondary)
                            
                            Text("将您最爱的照片变成桌面上的精美拍立得贴纸")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(15)
                    }
                    
                    HStack {
                        Spacer()
                        Button("重置所有设置") {
                            resetSettings()
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }
                    .padding(.top, 20)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
        .frame(minWidth: 600, minHeight: 600)
    }
    
    private func resetSettings() {
        defaultSizeString = "300,350"
        defaultColorString = "#FFFFFF"
        defaultFrameWidth = 20
        defaultShadow = 10
        autoSave = true
        showGrid = false
        gridSize = 10
    }
}

// Color扩展：从十六进制字符串创建Color
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}
