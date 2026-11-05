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
    func process(_ render: MuseVoice.Rendered,
                 inputTexture: MTLTexture,
                 outputTexture: MTLTexture,
                 sample: Float)
}

extension Effect {
    // Core needs for a effect texture processor.
    func initialize() -> (device: MTLDevice, queue: MTLCommandQueue, buffer: MTLCommandBuffer)? {
        if let device = kernel.context.device,
           let queue = device.makeCommandQueue(),
           let buffer = queue.makeCommandBuffer() {
            do {
                try device.makeDefaultLibrary(bundle: .module)
            } catch let error {
                print("Making device library: \(error)")
            }
            return (device, queue, buffer)
        }
        
        return nil
    }
    
    
}
