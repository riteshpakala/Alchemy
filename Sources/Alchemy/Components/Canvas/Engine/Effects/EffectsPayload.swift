//
//  EffectsPayload.swift
//  Alchemy
//
//  Created by Ritesh Pakala Rao on 10/31/26.
//

import MetalKit

/// A reusable payload that bundles all inputs to `Effect.encode`.
/// Provides an `updating` helper to create variants with changed fields.
struct EffectsPayload {
    let render: MuseVoice.Rendered
    let inputTexture: MTLTexture
    let outputTexture: MTLTexture
    let sample: Float
    let time: Float
    
    /// Creates a new payload with the given fields replaced.
    func updating(sample: Float? = nil, time: Float? = nil) -> EffectsPayload {
        EffectsPayload(
            render: render,
            inputTexture: inputTexture,
            outputTexture: outputTexture,
            sample: sample ?? self.sample,
            time: time ?? self.time
        )
    }
}
