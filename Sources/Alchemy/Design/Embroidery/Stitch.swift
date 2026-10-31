//
//  Stitch.swift
//  Alchemy
//
//  WHAT: A running stitch along any shape's outline — thread on top, a gap
//        where it dips under the cloth — with the shadow a raised stitch
//        casts and the sheen along its twist.
//  IN:   any Shape: `.stitched()`; StitchLine for a straight seam
//  OUT:  a non-interactive view the size of the shape
//
//    RoundedRectangle(cornerRadius: 22).inset(by: 8).stitched()
//    StitchLine().stitched(Brand.rust).frame(height: 4)
//

import SwiftUI

extension Shape {
    /// A running stitch along this shape's outline.
    public func stitched(
        _ thread: Brand.Thread = Brand.ink,
        length: CGFloat = Brand.stitchLength,
        gap: CGFloat = Brand.stitchGap,
        width: CGFloat = Brand.threadWidth
    ) -> some View {
        StitchedOutline(shape: self, thread: thread, length: length, gap: gap, width: width)
    }
}

struct StitchedOutline<S: Shape>: View {
    let shape: S
    let thread: Brand.Thread
    let length: CGFloat
    let gap: CGFloat
    let width: CGFloat

    /// Round caps lengthen each stitch by its width; the dash is shortened to match.
    private func style(_ lineWidth: CGFloat) -> StrokeStyle {
        StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round,
                    dash: [max(0.1, length - width), gap + width])
    }

    var body: some View {
        ZStack {
            // The shadow each stitch casts on the cloth, down and to the right.
            shape.stroke(thread.shadow, style: style(width + 0.4))
                .offset(x: 0.5, y: 0.8)
            shape.stroke(thread.color, style: style(width))
            // The sheen along the twist, up and to the left.
            shape.stroke(thread.sheen.opacity(0.75), style: style(width * 0.35))
                .offset(x: -width * 0.18, y: -width * 0.18)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A straight seam across the middle of its frame.
public struct StitchLine: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}
