//
//  EmbroideredPatch.swift
//  Alchemy
//
//  WHAT: A patch of linen sewn onto the cloth — the icon's tile: a lighter
//        square of fabric, a running stitch holding it on, lifted by a soft
//        shadow — with an embroidered title and anything inside it.
//  IN:   any content
//  OUT:  the content on its patch
//
//    EmbroideredPatch("Words") { … }
//    EmbroideredPatch(thread: Brand.rust) { … }
//

import SwiftUI

public struct EmbroideredPatch<Content: View>: View {
    var title: String?
    var thread: Brand.Thread
    var content: Content

    public init(_ title: String? = nil, thread: Brand.Thread = Brand.ink, @ViewBuilder content: () -> Content) {
        self.title = title
        self.thread = thread
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title {
                Text(title)
                    .font(Brand.serif(15, weight: .semibold))
                    .embroidered(Brand.sepia)
            }
            content
        }
        .padding(Brand.patchStitchInset + 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { PatchCloth(thread: thread) }
    }
}

/// The patch itself: fabric, weave, the stitch that holds it on, its cut edge.
struct PatchCloth: View {
    var thread: Brand.Thread

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Brand.patchRadius, style: .continuous)
        ZStack {
            shape.fill(Brand.patch)
            LinenTexture(spacing: 2).clipShape(shape)
            shape.inset(by: Brand.patchStitchInset).stitched(thread)
            shape.strokeBorder(Brand.weave.opacity(0.45), lineWidth: 0.8)
        }
        .shadow(color: Brand.fabricShadow.opacity(0.16), radius: 12, x: 0, y: 6)
        .shadow(color: Brand.fabricShadow.opacity(0.10), radius: 1.5, x: 0, y: 1)
    }
}
