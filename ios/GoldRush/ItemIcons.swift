import SwiftUI

/// Hand-drawn vector icons for gold item types — no emoji.
struct ItemIcon: View {
    let type: String
    var size: CGFloat = 18
    var color: Color = Theme.gold

    private var lw: CGFloat { max(1.4, size * 0.09) }

    var body: some View {
        content.frame(width: size, height: size)
    }

    @ViewBuilder private var content: some View {
        switch type {
        case "ring":
            ZStack {
                Circle().stroke(color, lineWidth: lw)
                    .frame(width: size * 0.66, height: size * 0.66)
                    .offset(y: size * 0.14)
                Diamond().fill(color)
                    .frame(width: size * 0.3, height: size * 0.3)
                    .offset(y: -size * 0.32)
            }
        case "necklace":
            ZStack {
                Arc().stroke(color, style: StrokeStyle(lineWidth: lw, lineCap: .round))
                    .frame(width: size * 0.82, height: size * 0.82)
                    .offset(y: -size * 0.06)
                Circle().fill(color)
                    .frame(width: size * 0.2, height: size * 0.2)
                    .offset(y: size * 0.33)
            }
        case "bracelet":
            Ellipse().stroke(color, lineWidth: lw)
                .frame(width: size * 0.84, height: size * 0.58)
        case "pendant":
            Diamond().fill(color)
                .frame(width: size * 0.58, height: size * 0.8)
        case "coin":
            ZStack {
                Circle().fill(color.opacity(0.25))
                Circle().stroke(color, lineWidth: lw)
                Circle().stroke(color.opacity(0.55), lineWidth: lw * 0.6)
                    .frame(width: size * 0.48, height: size * 0.48)
            }
            .frame(width: size * 0.82, height: size * 0.82)
        default: // bar / wafer
            Trapezoid().fill(color)
                .frame(width: size * 0.84, height: size * 0.5)
        }
    }
}

struct Diamond: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.midY))
        p.closeSubpath()
        return p
    }
}

struct Arc: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: r.midX, y: r.midY),
                 radius: r.width / 2,
                 startAngle: .degrees(155), endAngle: .degrees(25),
                 clockwise: false)
        return p
    }
}

struct Trapezoid: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let inset = r.width * 0.15
        p.move(to: CGPoint(x: r.minX + inset, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - inset, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}
