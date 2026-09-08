import AppKit

// SVG viewBox of the menu-bar glyph.
let svgW: CGFloat = 223
let svgH: CGFloat = 227

let outDir = "/Users/neo/workspace/huhTray/huhTray/Assets.xcassets/AppIcon.appiconset"
let pixelSizes: [Int] = [16, 32, 64, 128, 256, 512, 1024]

func renderIcon(px: Int) -> Data {
    let size = CGFloat(px)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // Rounded-tile background with a green gradient (slight margin like a macOS tile).
    let inset = size * 0.06
    let bgRect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let bgRadius = bgRect.width * 0.2237
    let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: bgRadius, yRadius: bgRadius)
    let gradient = NSGradient(
        starting: NSColor(calibratedRed: 0.42, green: 0.68, blue: 0.29, alpha: 1),
        ending: NSColor(calibratedRed: 0.22, green: 0.46, blue: 0.16, alpha: 1)
    )!
    gradient.draw(in: bgPath, angle: -90)

    // Map SVG coordinates (y-down) into the canvas (y-up), centered.
    let glyphFraction: CGFloat = 0.52
    let scale = (size * glyphFraction) / max(svgW, svgH)
    let drawW = svgW * scale
    let drawH = svgH * scale
    let offsetX = (size - drawW) / 2
    let offsetTop = (size - drawH) / 2

    let transform = NSAffineTransform()
    transform.translateX(by: offsetX, yBy: size - offsetTop)
    transform.scaleX(by: scale, yBy: -scale)
    transform.concat()

    NSColor.white.setFill()
    NSColor.white.setStroke()

    // Outline rounded rect, with the bottom-center notch cut out (the SVG mask).
    NSGraphicsContext.saveGraphicsState()
    let clip = NSBezierPath()
    clip.appendRect(NSRect(x: -1000, y: -1000, width: 4000, height: 4000))
    clip.appendRect(NSRect(x: 77, y: 172, width: 68, height: 28))
    clip.windingRule = .evenOdd
    clip.setClip()

    let outline = NSBezierPath(roundedRect: NSRect(x: 24, y: 23, width: 174, height: 164), xRadius: 6, yRadius: 6)
    outline.lineWidth = 14
    outline.stroke()
    NSGraphicsContext.restoreGraphicsState()

    // Filled shapes (mouth bar, eyes, body).
    func fillRounded(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) {
        NSBezierPath(roundedRect: NSRect(x: x, y: y, width: w, height: h), xRadius: r, yRadius: r).fill()
    }
    fillRounded(44, 59, 134, 15, 2)
    fillRounded(63, 87, 22, 22, 3)
    fillRounded(137, 87, 22, 22, 3)
    fillRounded(85, 118, 52, 91, 5)

    NSGraphicsContext.restoreGraphicsState()

    return rep.representation(using: .png, properties: [:])!
}

for px in pixelSizes {
    let data = renderIcon(px: px)
    let url = URL(fileURLWithPath: "\(outDir)/icon_\(px).png")
    try! data.write(to: url)
    print("wrote icon_\(px).png")
}
