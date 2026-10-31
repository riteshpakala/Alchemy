//
//  StitchedControls.swift
//  Alchemy
//
//  WHAT: Controls that look sewn: a text field written in thread over a
//        running-stitch seam, and a button that is a small stitched patch.
//  IN:   any page
//  OUT:  StitchedTextField; `.buttonStyle(.stitched)`
//  PIN:  The field takes `.threaded()`, never `.embroidered()`: a mask would
//        draw a second, focusable field under the first.
//

import SwiftUI

/// A line of text written in thread over a running-stitch seam.
public struct StitchedTextField: View {
    var placeholder: String
    @Binding var text: String
    var onSubmit: () -> Void

    public init(_ placeholder: String, text: Binding<String>, onSubmit: @escaping () -> Void = {}) {
        self.placeholder = placeholder
        self._text = text
        self.onSubmit = onSubmit
    }

    public var body: some View {
        TextField(
            "", text: $text,
            prompt: Text(placeholder).foregroundStyle(Brand.sepia.color.opacity(0.65)))
            .textFieldStyle(.plain)
            .font(Brand.serif(17))
            .threaded(Brand.ink)
            .padding(.vertical, 8)
            .overlay(alignment: .bottom) {
                StitchLine().stitched(Brand.sepia, length: 5, gap: 3.5, width: 1.3)
                    .frame(height: 4)
                    .offset(y: 2)
            }
            .onSubmit(onSubmit)
    }
}

/// A small patch with a rust running stitch around its label.
public struct StitchedButtonStyle: ButtonStyle {
    var thread: Brand.Thread

    public init(thread: Brand.Thread = Brand.rust) {
        self.thread = thread
    }

    public func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .font(Brand.serif(14, weight: .semibold))
            .embroidered(thread)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background {
                let shape = Capsule(style: .continuous)
                ZStack {
                    shape.fill(Brand.patch)
                    shape.inset(by: 4).stitched(thread, length: 4, gap: 3, width: 1.3)
                    shape.strokeBorder(Brand.weave.opacity(0.5), lineWidth: 0.8)
                }
                .shadow(color: Brand.fabricShadow.opacity(pressed ? 0.06 : 0.16),
                        radius: pressed ? 1 : 4, x: 0, y: pressed ? 0.5 : 2)
            }
            .scaleEffect(pressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: pressed)
    }
}

extension ButtonStyle where Self == StitchedButtonStyle {
    /// A small stitched patch, in rust.
    public static var stitched: StitchedButtonStyle { StitchedButtonStyle() }
}
