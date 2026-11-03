import AppKit
import CoreGraphics

func generateAnimattoBunnyIcon(size: CGSize) -> NSImage {
    let image = NSImage(size: size)
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }
    
    let rect = CGRect(origin: .zero, size: size)
    let s = min(size.width, size.height)
    
    // Squircle container with 22.4% corner radius (macOS HIG standard squircle)
    let margin = s * 0.04
    let iconRect = rect.insetBy(dx: margin, dy: margin)
    let cornerRadius = iconRect.width * 0.224
    let path = CGPath(roundedRect: iconRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    
    // Outer ambient shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.03), blur: s * 0.06, color: CGColor(gray: 0.0, alpha: 0.45))
    ctx.setFillColor(CGColor(gray: 0.1, alpha: 1.0))
    ctx.addPath(path)
    ctx.fillPath()
    ctx.restoreGState()
    
    // Squircle background gradient: Rich dark graphite to deep obsidian
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        CGColor(red: 0.14, green: 0.15, blue: 0.17, alpha: 1.0),
        CGColor(red: 0.08, green: 0.09, blue: 0.10, alpha: 1.0)
    ] as CFArray
    let bgLocations: [CGFloat] = [0.0, 1.0]
    if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
        ctx.drawLinearGradient(bgGradient, start: CGPoint(x: iconRect.midX, y: iconRect.maxY), end: CGPoint(x: iconRect.midX, y: iconRect.minY), options: [])
    }
    
    // Inner subtle glow/radial lighting at the top
    let glowColors = [
        CGColor(red: 1.0, green: 0.35, blue: 0.37, alpha: 0.12),
        CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
    ] as CFArray
    if let glowGradient = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(glowGradient, startCenter: CGPoint(x: iconRect.midX, y: iconRect.maxY * 0.8), startRadius: 0, endCenter: CGPoint(x: iconRect.midX, y: iconRect.midY), endRadius: iconRect.width * 0.55, options: [])
    }
    
    // Draw the Bunny Symbol
    let symbolPointSize = iconRect.width * 0.52
    let config = NSImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .semibold)
    if let baseSymbol = NSImage(systemSymbolName: "hare.fill", accessibilityDescription: nil)?.withSymbolConfiguration(config) {
        // Render symbol into mask / tinted coral gradient
        let symbolSize = baseSymbol.size
        // Optical centering: the bunny ears extend left/top, shift slightly right (+3%) and down (-2%) for perfect optical center
        let targetX = iconRect.midX - (symbolSize.width / 2.0) + (iconRect.width * 0.02)
        let targetY = iconRect.midY - (symbolSize.height / 2.0) - (iconRect.height * 0.02)
        let symbolRect = CGRect(x: targetX, y: targetY, width: symbolSize.width, height: symbolSize.height)
        
        ctx.saveGState()
        // Draw bunny drop shadow
        ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.02), blur: s * 0.04, color: CGColor(red: 1.0, green: 0.25, blue: 0.30, alpha: 0.35))
        
        // Use symbol mask to fill vibrant coral red gradient
        // To draw gradient inside SF symbol:
        // First draw the symbol in a secondary buffer or use CoreGraphics clip
        let symbolImage = NSImage(size: symbolSize)
        symbolImage.lockFocus()
        baseSymbol.draw(in: CGRect(origin: .zero, size: symbolSize))
        symbolImage.unlockFocus()
        
        if let cgSymbol = symbolImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            ctx.clip(to: symbolRect, mask: cgSymbol)
            
            // Coral Gradient: `#FF6B6B` (top) to `#FF453A` (bottom)
            let coralColors = [
                CGColor(red: 1.00, green: 0.44, blue: 0.42, alpha: 1.0), // Coral bright
                CGColor(red: 1.00, green: 0.27, blue: 0.23, alpha: 1.0)  // Vivid coral red
            ] as CFArray
            if let coralGradient = CGGradient(colorsSpace: colorSpace, colors: coralColors, locations: [0.0, 1.0]) {
                ctx.drawLinearGradient(coralGradient, start: CGPoint(x: symbolRect.midX, y: symbolRect.maxY), end: CGPoint(x: symbolRect.midX, y: symbolRect.minY), options: [])
            }
        }
        ctx.restoreGState()
    }
    
    // Inner 1pt highlight border along top edge
    let borderPath = CGPath(roundedRect: iconRect.insetBy(dx: 0.75, dy: 0.75), cornerWidth: cornerRadius - 0.75, cornerHeight: cornerRadius - 0.75, transform: nil)
    ctx.addPath(borderPath)
    ctx.setLineWidth(1.5 * (s / 512.0))
    ctx.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.15))
    ctx.strokePath()
    
    ctx.restoreGState()
    
    image.unlockFocus()
    return image
}

func savePNG(image: NSImage, targetURL: URL) {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to encode PNG for:", targetURL)
        return
    }
    do {
        try pngData.write(to: targetURL)
        print("Wrote:", targetURL.path, "(\(image.size.width)x\(image.size.height))")
    } catch {
        print("Failed to write to:", targetURL.path, error)
    }
}

let appIconDir = URL(fileURLWithPath: "Animatto/Assets.xcassets/AppIcon.appiconset")

let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (filename, dimension) in sizes {
    let img = generateAnimattoBunnyIcon(size: CGSize(width: dimension, height: dimension))
    savePNG(image: img, targetURL: appIconDir.appendingPathComponent(filename))
}

// Master logo and web assets
let master1024 = generateAnimattoBunnyIcon(size: CGSize(width: 1024, height: 1024))
savePNG(image: master1024, targetURL: URL(fileURLWithPath: "Animatto-Logo.png"))

let webAppIcon = generateAnimattoBunnyIcon(size: CGSize(width: 512, height: 512))
savePNG(image: webAppIcon, targetURL: URL(fileURLWithPath: "web/assets/app_icon.png"))

let favicon = generateAnimattoBunnyIcon(size: CGSize(width: 64, height: 64))
savePNG(image: favicon, targetURL: URL(fileURLWithPath: "web/assets/favicon.png"))
