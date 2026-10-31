//
//  Embroidered.swift
//  Alchemy
//
//  WHAT: Any view filled in thread, as a satin stitch: the thread's colour,
//        fine slanted stitches catching the light across it, and the raised
//        edge's shadow on the cloth.
//  IN:   text, symbols, shapes — anything drawn in its foreground style
//  OUT:  the same view, sewn
//  PIN:  The view is drawn twice (once as itself, once as the mask the satin
//        lies in), so it suits what only draws: text, images, shapes. A
//        control that holds state or focus (a text field) takes `.threaded()`,
//        the same thread without the mask.
//
//    Text("Alchemy").font(Brand.serif(34)).embroidered()
//    Image(systemName: "hand.raised").embroidered(Brand.rust, angle: .degrees(60))
//

import SwiftUI

extension View {
    /// This view, sewn in `thread` with satin stitches slanted at `angle`.
    public func embroidered(_ thread: Brand.Thread = Brand.ink, angle: Angle = .degrees(-35)) -> some View {
        modifier(Embroidered(thread: thread, angle: angle))
    }

    /// This view's foreground in `thread`, raised off the cloth: for controls,
    /// which must not be drawn twice.
    public func threaded(_ thread: Brand.Thread = Brand.ink) -> some View {
        foregroundStyle(thread.color)
            .shadow(color: thread.shadow, radius: 0.2, x: 0.4, y: 0.6)
    }
}

struct Embroidered: ViewModifier {
    let thread: Brand.Thread
    let angle: Angle

    func body(content: Content) -> some View {
        content
            .foregroundStyle(thread.color)
            .overlay {
                SatinStitches(angle: angle)
                    .foregroundStyle(thread.sheen.opacity(0.55))
                    .mask(content)
            }
            // The raised edge, then the soft fall-off where the thread lifts the cloth.
            .shadow(color: thread.shadow, radius: 0.3, x: 0.5, y: 0.8)
            .shadow(color: Brand.fabricShadow.opacity(0.12), radius: 1.2, x: 0, y: 1.2)
    }
}

/// Parallel slanted stitches filling the frame: the satin's light.
struct SatinStitches: View {
    var angle: Angle
    /// Distance between neighbouring stitches.
    var pitch: CGFloat = 1.8

    var body: some View {
        SwiftUI.Canvas { context, size in
            let slope = CGFloat(tan(angle.radians))
            let rise = size.height * slope
            var path = Path()
            var x = -abs(rise) - pitch
            while x <= size.width + abs(rise) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x + rise, y: size.height))
                x += pitch
            }
            context.stroke(path, with: .foreground, lineWidth: pitch * 0.35)
        }
        .allowsHitTesting(false)
    }
}
