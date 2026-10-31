//
//  Effect.swift
//  Alchemy
//
//  Created by Ritesh Pakala Rao on 10/31/26.
//

import Foundation
import MetalKit

protocol Effect {
    var kernel: EffectKernel { get set }
    func process(_ render: MuseVoice.Rendered)
}

extension Effect {
    // Core needs for a effect texture processor.
    func initialize() -> (device: MTLDevice, queue: MTLCommandQueue, buffer: MTLCommandBuffer)? {
        if let device = kernel.context.device,
           let queue = device.makeCommandQueue(),
           let buffer = queue.makeCommandBuffer() {
            return (device, queue, buffer)
        }
        
        return nil
    }
    
    func createDescriptor() -> MTLTextureDescriptor {
        // TODO: width and height should scale with UI?
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: 1080,
            height: 1080,
            mipmapped: false
        )
        
        descriptor.storageMode = .shared
        descriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        
        return descriptor
    }
    
    func createBaseTexture(_ device: MTLDevice?) -> MTLTexture? {
        (device ?? kernel.context.device)?.makeTexture(descriptor: createDescriptor())
    }
}
