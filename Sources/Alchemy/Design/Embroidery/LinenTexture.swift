//
//  LinenTexture.swift
//  Alchemy
//
//  WHAT: Woven linen — fine warp and weft lines with the odd thicker slub —
//        to lay under anything that should read as cloth.
//  IN:   Home's background, EmbroideredPatch
//  OUT:  a non-interactive texture that fills its frame
//  PIN:  The slubs come from a fixed seed: the cloth never shimmers when the
//        view redraws or resizes.
//

import SwiftUI

public struct LinenTexture: View {
    var tint: Color
    /// Distance between neighbouring threads, in points.
    var spacing: CGFloat

    public init(tint: Color = Brand.weave, spacing: CGFloat = 2.5) {
        self.tint = tint
        self.spacing = spacing
    }

    public var body: some View {
        SwiftUI.Canvas { context, size in
            var warp = Path()
            var y: CGFloat = 0
            while y <= size.height {
                warp.move(to: CGPoint(x: 0, y: y))
                warp.addLine(to: CGPoint(x: size.width, y: y))
                y += spacing
            }
            context.stroke(warp, with: .color(tint.opacity(0.16)), lineWidth: 0.5)

            var weft = Path()
            var x: CGFloat = 0
            while x <= size.width {
                weft.move(to: CGPoint(x: x, y: 0))
                weft.addLine(to: CGPoint(x: x, y: size.height))
                x += spacing
            }
            context.stroke(weft, with: .color(tint.opacity(0.11)), lineWidth: 0.5)

            // Slubs: short, thicker runs where the yarn was uneven.
            var random = SeededRandom(seed: 0xA1C4E)
            var slubs = Path()
            let count = Int(size.width * size.height / 700)
            for _ in 0..<count {
                let horizontal = random.next() < 0.6
                let start = CGPoint(
                    x: (random.next() * size.width / spacing).rounded() * spacing,
                    y: (random.next() * size.height / spacing).rounded() * spacing)
                let length = 4 + random.next() * 14
                slubs.move(to: start)
                slubs.addLine(to: horizontal
                    ? CGPoint(x: start.x + length, y: start.y)
                    : CGPoint(x: start.x, y: start.y + length))
            }
            context.stroke(slubs, with: .color(tint.opacity(0.22)), lineWidth: 1)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A fixed sequence in 0..<1 (SplitMix64): the same cloth every time.
struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> CGFloat {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return CGFloat(z >> 11) / CGFloat(1 << 53)
    }
}
