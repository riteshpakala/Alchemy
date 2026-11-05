//
//  Effect.Whirl.swift
//  Alchemy
//
//  Created by Ritesh Pakala Rao on 10/31/26.
//

import SwiftUI
import MetalKit

struct Whirl: Effect {
    var kernel: EffectKernel
    
    init(context: MetalContext) {
        self.kernel = .init(context: context, fragmentShaderName: "whirl")
    }
    
    
    func process(_ render: MuseVoice.Rendered,
                 inputTexture: MTLTexture,
                 outputTexture: MTLTexture,
                 sample: Float = 1.0) {
        guard let (device, queue, buffer) = self.initialize() else {
            fatalError("Could not initialize Effect.")
        }
        
        guard let encoder = buffer.makeComputeCommandEncoder() else {
            fatalError("Could not create command encoder.")
        }
        
        guard let pipelineState = kernel.pipelineFunction else {
            fatalError("Could not find pipeline function.")
        }
        
        // Make the buffer
        let floatBuffer = device.makeBuffer(length: MemoryLayout<Float>.size)
        
        var mutableSample = sample
        
        // Store the float value into the mtlbuffer directly
        floatBuffer?
            .contents()
            .storeBytes(of: mutableSample, as: Float.self)
        
        encoder.setComputePipelineState(pipelineState)
        encoder.setTexture(inputTexture, index: 0)
        encoder.setTexture(outputTexture, index: 1)
        encoder.setBuffer(floatBuffer, offset: 0, index: 0)
        
        let width = inputTexture.width
        let height = inputTexture.height

        encoder
            .dispatchThreadgroups(
                .init(width: (width + 15) / 16, height: (height + 15) / 16, depth: 1),
                threadsPerThreadgroup: .init(width: min(16, width), height: min(16, height), depth: 1)
            )
        
        encoder.endEncoding()
        
        buffer.commit()
        buffer.waitUntilCompleted()
    }
}
