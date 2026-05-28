import AppKit
import Foundation

enum IconVariant {
    case light
    case dark
    case tinted

    var background: NSColor {
        switch self {
        case .light: NSColor(red: 0.04, green: 0.07, blue: 0.11, alpha: 1)
        case .dark: NSColor(red: 0.92, green: 0.97, blue: 0.96, alpha: 1)
        case .tinted: NSColor(red: 0.10, green: 0.48, blue: 0.52, alpha: 1)
        }
    }

    var foreground: NSColor {
        switch self {
        case .light, .tinted: .white
        case .dark: NSColor(red: 0.04, green: 0.07, blue: 0.11, alpha: 1)
        }
    }
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputDirectory = root.appendingPathComponent("Kiezio/Assets.xcassets/AppIcon.appiconset")

let icons: [(filename: String, size: Int, variant: IconVariant)] = [
    ("AppIcon-1024.png", 1024, .light),
    ("AppIcon-Dark-1024.png", 1024, .dark),
    ("AppIcon-Tinted-1024.png", 1024, .tinted),
    ("AppIcon-mac-16.png", 16, .light),
    ("AppIcon-mac-32.png", 32, .light),
    ("AppIcon-mac-32@2x.png", 64, .light),
    ("AppIcon-mac-128.png", 128, .light),
    ("AppIcon-mac-128@2x.png", 256, .light),
    ("AppIcon-mac-256.png", 256, .light),
    ("AppIcon-mac-256@2x.png", 512, .light),
    ("AppIcon-mac-512.png", 512, .light),
    ("AppIcon-mac-512@2x.png", 1024, .light)
]

for icon in icons {
    let size = CGFloat(icon.size)
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: icon.size,
        pixelsHigh: icon.size,
        bitsPerSample: 8,
        samplesPerPixel: 3,
        hasAlpha: false,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Could not create bitmap rep")
    }
    rep.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    icon.variant.background.setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()

    let tileSize = size * 0.25
    let radius = size * 0.055
    let colors = [
        NSColor(red: 0.00, green: 0.60, blue: 0.62, alpha: 1),
        NSColor(red: 0.05, green: 0.40, blue: 0.82, alpha: 1),
        NSColor(red: 0.95, green: 0.30, blue: 0.24, alpha: 1),
        NSColor(red: 0.16, green: 0.66, blue: 0.40, alpha: 1)
    ]
    let origins = [
        CGPoint(x: size * 0.14, y: size * 0.58),
        CGPoint(x: size * 0.58, y: size * 0.58),
        CGPoint(x: size * 0.14, y: size * 0.14),
        CGPoint(x: size * 0.58, y: size * 0.14)
    ]

    for (index, origin) in origins.enumerated() {
        colors[index].setFill()
        NSBezierPath(
            roundedRect: NSRect(x: origin.x, y: origin.y, width: tileSize, height: tileSize),
            xRadius: radius,
            yRadius: radius
        ).fill()
    }

    let font = NSFont.systemFont(ofSize: size * 0.43, weight: .black)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: icon.variant.foreground
    ]
    let text = "K" as NSString
    let textSize = text.size(withAttributes: attributes)
    text.draw(
        at: CGPoint(x: (size - textSize.width) / 2, y: (size - textSize.height) / 2 - size * 0.02),
        withAttributes: attributes
    )

    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode PNG")
    }
    try data.write(to: outputDirectory.appendingPathComponent(icon.filename), options: .atomic)
}
