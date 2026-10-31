//
//  Brand.swift
//  Alchemy
//
//  WHAT: Alchemy's look, in one place: thread on linen, as in the icon — a
//        hand drawn in near-black thread on cream fabric, a rust running
//        stitch at the cuff, the patch lifted off the cloth by a soft shadow.
//  IN:   every view; the embroidery kit (Design/Embroidery)
//  OUT:  colours, threads, stitch metrics, type
//

import SwiftUI

public struct Brand: Sendable {

    // MARK: - Fabric

    /// The cloth everything is sewn onto.
    public static let linen = Color(red: 0.953, green: 0.933, blue: 0.890)        // #F3EEE3
    /// A patch: the same linen, a shade lighter, as the icon's tile.
    public static let patch = Color(red: 0.984, green: 0.973, blue: 0.945)        // #FBF8F1
    /// Warp and weft — the woven lines in the cloth.
    public static let weave = Color(red: 0.788, green: 0.741, blue: 0.659)        // #C9BDA8
    /// What the cloth casts when it is lifted.
    public static let fabricShadow = Color(red: 0.333, green: 0.278, blue: 0.220)  // #554738

    // MARK: - Threads

    /// A colour of thread: its fill, the sheen along each twist, and the shadow
    /// a raised stitch casts on the cloth.
    public struct Thread: Sendable, Hashable {
        public var color: Color
        public var sheen: Color
        public var shadow: Color

        public init(color: Color, sheen: Color, shadow: Color) {
            self.color = color
            self.sheen = sheen
            self.shadow = shadow
        }
    }

    /// The drawing's thread: near-black brown.
    public static let ink = Thread(
        color: Color(red: 0.165, green: 0.141, blue: 0.125),    // #2A2420
        sheen: Color(red: 0.420, green: 0.365, blue: 0.322),    // #6B5D52
        shadow: Color.black.opacity(0.30))
    /// Captions and quiet things: a faded brown.
    public static let sepia = Thread(
        color: Color(red: 0.420, green: 0.353, blue: 0.298),    // #6B5A4C
        sheen: Color(red: 0.627, green: 0.549, blue: 0.482),    // #A08C7B
        shadow: Color.black.opacity(0.18))
    /// The cuff's running stitch: rust red, for the one thing to press.
    public static let rust = Thread(
        color: Color(red: 0.659, green: 0.263, blue: 0.184),    // #A8432F
        sheen: Color(red: 0.851, green: 0.510, blue: 0.420),    // #D9826B
        shadow: Color(red: 0.30, green: 0.08, blue: 0.04).opacity(0.35))

    // MARK: - Stitches

    /// A running stitch: thread on top for `stitchLength`, under the cloth for `stitchGap`.
    public static let stitchLength: CGFloat = 6
    public static let stitchGap: CGFloat = 4
    /// One strand's width on screen.
    public static let threadWidth: CGFloat = 1.6
    /// A patch's corner, the icon's.
    public static let patchRadius: CGFloat = 22
    /// How far a patch's border stitch sits inside its edge.
    public static let patchStitchInset: CGFloat = 8

    // MARK: - Type

    /// Words sewn in: a serif, as a hand would draw the letters.
    public static func serif(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// Numbers that line up.
    public static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
