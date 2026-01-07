import SwiftUI
import AppKit

struct Polaroid: Identifiable, Codable, Equatable {
    let id: UUID
    var imageData: Data?
    var frameColorData: ColorData
    var frameWidth: CGFloat
    var shadowRadius: CGFloat
    var rotation: Double
    var position: CGPoint
    var size: CGSize
    var title: String
    var date: Date
    var isPinned: Bool
    
    // 计算属性：转换为 Color
    var frameColor: Color {
        get {
            frameColorData.color
        }
        set {
            frameColorData = ColorData(color: newValue)
        }
    }
    
    // 计算属性：转换为 NSImage
    var nsImage: NSImage? {
        guard let data = imageData else { return nil }
        return NSImage(data: data)
    }
    
    init(id: UUID = UUID(),
         imageData: Data? = nil,
         frameColor: Color = .white,
         frameWidth: CGFloat = 20,
         shadowRadius: CGFloat = 10,
         rotation: Double = 0,
         position: CGPoint = CGPoint(x: 100, y: 100),
         size: CGSize = CGSize(width: 300, height: 350),
         title: String = "",
         date: Date = Date(),
         isPinned: Bool = false) {
        self.id = id
        self.imageData = imageData
        self.frameColorData = ColorData(color: frameColor)
        self.frameWidth = frameWidth
        self.shadowRadius = shadowRadius
        self.rotation = rotation
        self.position = position
        self.size = size
        self.title = title
        self.date = date
        self.isPinned = isPinned
    }
    
    // 实现 Equatable
    static func == (lhs: Polaroid, rhs: Polaroid) -> Bool {
        return lhs.id == rhs.id &&
               lhs.imageData == rhs.imageData &&
               lhs.frameColorData == rhs.frameColorData &&
               lhs.frameWidth == rhs.frameWidth &&
               lhs.shadowRadius == rhs.shadowRadius &&
               lhs.rotation == rhs.rotation &&
               lhs.position.x == rhs.position.x &&
               lhs.position.y == rhs.position.y &&
               lhs.size.width == rhs.size.width &&
               lhs.size.height == rhs.size.height &&
               lhs.title == rhs.title &&
               lhs.date == rhs.date &&
               lhs.isPinned == rhs.isPinned
    }
}

// 用于存储颜色的可编码结构体
struct ColorData: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double
    
    init(color: Color) {
        let nsColor = NSColor(color)
        let rgba = nsColor.usingColorSpace(.sRGB) ?? NSColor.white.usingColorSpace(.sRGB)!
        self.red = Double(rgba.redComponent)
        self.green = Double(rgba.greenComponent)
        self.blue = Double(rgba.blueComponent)
        self.alpha = Double(rgba.alphaComponent)
    }
    
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}
