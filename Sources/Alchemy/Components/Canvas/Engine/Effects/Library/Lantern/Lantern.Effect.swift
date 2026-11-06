//
//  Effect.Lantern.swift
//  Alchemy
//
//  Created by Ritesh Pakala Rao on 10/31/26.
//

import SwiftUI
import MetalKit

struct Lantern: Effect {
    var kernel: EffectKernel
    
    init(_ context: MetalContext) {
        self.kernel = .init(
            context: context,
            fragmentShaderName: Engine.Catalogue
                .lantern.rawValue)
    }
    
    func isEquals(_ kind: Engine.Catalogue) -> Bool {
        kind.rawValue
            .lowercased() == kernel.fragmentShaderName
            .lowercased()
    }
    
    
    func encode(_ payload: EffectsPayload) {
        guard let (device, _, buffer) = self.initialize() else {
            fatalError("Could not initialize.")
        }
        
        guard let encoder = buffer.makeComputeCommandEncoder() else {
            fatalError("Could not create command encoder.")
        }
        
        guard let pipelineState = kernel.pipelineFunction else {
            fatalError("Could not find pipeline function.")
        }
        
        // Make the buffer
        let floatBuffer = device.makeBuffer(length: MemoryLayout<Float>.size)
        
        let mutableSample = payload.sample
        
        // Store the float value into the mtlbuffer directly
        floatBuffer?
            .contents()
            .storeBytes(of: mutableSample, as: Float.self)
        
        // Make the buffer
        let timeBuffer = device.makeBuffer(length: MemoryLayout<Float>.size)
        
        let mutableTime = payload.time
        
        // Store the float value into the mtlbuffer directly
        timeBuffer?
            .contents()
            .storeBytes(of: mutableTime, as: Float.self)
        
        encoder.setComputePipelineState(pipelineState)
        encoder.setTexture(payload.inputTexture, index: 0)
        encoder.setTexture(payload.outputTexture, index: 1)
        encoder.setBuffer(floatBuffer, offset: 0, index: 0)
        encoder.setBuffer(timeBuffer, offset: 0, index: 1)
        
        
        
        let width = payload.inputTexture.width
        let height = payload.inputTexture.height
        
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
