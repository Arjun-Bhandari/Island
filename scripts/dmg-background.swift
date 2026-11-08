// Renders Resources/dmg/background.tiff (1x + 2x) from the AI-painted base art.
// Layout constants must match the icon positions in scripts/dmg-settings.py.
// Usage: swift scripts/dmg-background.swift
import AppKit

let size = NSSize(width: 660, height: 400)
let appCenter = NSPoint(x: 165, y: 200)
let applicationsCenter = NSPoint(x: 495, y: 200)
let art = NSImage(contentsOfFile: "Resources/dmg/background-art.png")!

func render(scale: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = size
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    // Flip so y grows downward, matching Finder's icon coordinates.
    ctx.cgContext.translateBy(x: 0, y: size.height)
    ctx.cgContext.scaleBy(x: 1, y: -1)
    let flipped = NSGraphicsContext(cgContext: ctx.cgContext, flipped: true)
    NSGraphicsContext.current = flipped

    art.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .copy, fraction: 1, respectFlipped: true, hints: nil)

    // The notch the light spills out of, echoing the app icon's pill + orange dot.
    let notch = NSBezierPath()
    let nw: CGFloat = 168, nh: CGFloat = 32, r: CGFloat = 14
    let nx = (size.width - nw) / 2
    notch.move(to: NSPoint(x: nx - 8, y: 0))
    notch.curve(to: NSPoint(x: nx, y: 8), controlPoint1: NSPoint(x: nx, y: 0), controlPoint2: NSPoint(x: nx, y: 0))
    notch.line(to: NSPoint(x: nx, y: nh - r))
    notch.curve(to: NSPoint(x: nx + r, y: nh), controlPoint1: NSPoint(x: nx, y: nh), controlPoint2: NSPoint(x: nx, y: nh))
    notch.line(to: NSPoint(x: nx + nw - r, y: nh))
    notch.curve(to: NSPoint(x: nx + nw, y: nh - r), controlPoint1: NSPoint(x: nx + nw, y: nh), controlPoint2: NSPoint(x: nx + nw, y: nh))
    notch.line(to: NSPoint(x: nx + nw, y: 8))
    notch.curve(to: NSPoint(x: nx + nw + 8, y: 0), controlPoint1: NSPoint(x: nx + nw, y: 0), controlPoint2: NSPoint(x: nx + nw, y: 0))
    notch.close()
    NSColor.black.setFill()
    notch.fill()
    NSColor(white: 1, alpha: 0.9).setFill()
    NSBezierPath(roundedRect: NSRect(x: size.width / 2 - 26, y: 12, width: 52, height: 9), xRadius: 4.5, yRadius: 4.5).fill()
    NSColor(red: 1, green: 0.48, blue: 0.1, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: size.width / 2 + 13, y: 14, width: 5, height: 5)).fill()

    // Finder always draws icon names in black, so the icons sit on a light card
    // where those labels stay readable whatever the system appearance.
    let card = NSBezierPath(roundedRect: NSRect(x: 72, y: 110, width: 516, height: 186), xRadius: 24, yRadius: 24)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor(calibratedRed: 0.25, green: 0.4, blue: 1, alpha: 0.35)
    shadow.shadowBlurRadius = 40
    shadow.shadowOffset = .zero
    shadow.set()
    NSColor(white: 0.97, alpha: 1).setFill()
    card.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSColor(white: 1, alpha: 0.9).setStroke()
    card.lineWidth = 1
    card.stroke()

    // Dashed arc with a chevron: "this goes there".
    let arrow = NSBezierPath()
    arrow.move(to: NSPoint(x: 252, y: 196))
    arrow.curve(to: NSPoint(x: 404, y: 196), controlPoint1: NSPoint(x: 300, y: 160), controlPoint2: NSPoint(x: 356, y: 160))
    arrow.lineWidth = 2.5
    arrow.lineCapStyle = .round
    arrow.setLineDash([0.1, 9], count: 2, phase: 0)
    NSColor(white: 0, alpha: 0.28).setStroke()
    arrow.stroke()
    // Chevron arms point back along the curve's end tangent (tip minus last control point).
    let tip = NSPoint(x: 404, y: 196), tangent = atan2(196.0 - 160, 404.0 - 356)
    let head = NSBezierPath()
    for (i, spread) in [CGFloat.pi * 0.8, -CGFloat.pi * 0.8].enumerated() {
        let arm = NSPoint(x: tip.x + 12 * cos(tangent + spread), y: tip.y + 12 * sin(tangent + spread))
        if i == 0 { head.move(to: arm); head.line(to: tip) } else { head.line(to: arm) }
    }
    head.lineWidth = 2.5
    head.lineCapStyle = .round
    head.lineJoinStyle = .round
    head.stroke()

    let center = NSMutableParagraphStyle()
    center.alignment = .center
    NSAttributedString(string: "Drag Island into Applications", attributes: [
        .font: NSFont.systemFont(ofSize: 15, weight: .semibold),
        .foregroundColor: NSColor(white: 1, alpha: 0.92),
        .paragraphStyle: center,
    ]).draw(in: NSRect(x: 0, y: 312, width: size.width, height: 22))
    NSAttributedString(string: "First launch: System Settings → Privacy & Security → Open Anyway", attributes: [
        .font: NSFont.systemFont(ofSize: 11, weight: .regular),
        .foregroundColor: NSColor(white: 1, alpha: 0.55),
        .paragraphStyle: center,
    ]).draw(in: NSRect(x: 0, y: 336, width: size.width, height: 18))

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let tiff = NSBitmapImageRep.tiffRepresentationOfImageReps(in: [render(scale: 1), render(scale: 2)], using: .lzw, factor: 0)!
try! tiff.write(to: URL(fileURLWithPath: "Resources/dmg/background.tiff"))
let png = render(scale: 2).representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: "/tmp/dmgart/background-preview.png"))
print("Wrote Resources/dmg/background.tiff")
