//
//  Untitled.swift
//  Alchemy
//
//  Created by Ritesh Pakala Rao on 10/31/26.
//

import Foundation
import SwiftUI
import MetalKit

class Engine {
    enum Catalogue: String {
        case whirl = "whirl"
        case lantern = "lantern"
    }
    
    let context: MetalContext
    var effects: [Engine.Catalogue: Effect]
    var time: Float = 0.0
    
    /*
     
     1. Host kernels. A collection of kernels.
     2. Process hosts a kernel selection in MuseVoice.Rendered.
     3. MetalView hosts the engine in coordinator.
     4. Coordinator waits for a kernel selection to reach.
     5. UpdateNSView propagates a kernel selection into coordinator from a binding.
     
     */
    
    // TODO: load the effect kernels into a catalogue of options
    
    init(context: MetalContext) {
        self.context = context
        self.effects = [
            .whirl : Whirl(context),
            .lantern: Lantern(context)
        ]
    }
    
    // We want the engine to run a shader with a
    // audio render. Setting the texture which is
    // technically a fresh texture.
    //
    // The fresh texture is drawn with the audio
    // rendered samples.
    //
    // There can be multiple shaders, so we can
    // make a marble catalog again.
    
    
    // TODO: Replace fatals with logs.
    func process(
        _ render: MuseVoice.Rendered,
        inputTexture: MTLTexture? = nil,
        outputTexture: MTLTexture? = nil,
        effect: Catalogue = .whirl
    ) {
        guard let device = context.device else {
            fatalError("No device found.")
            return
        }
        
        guard let queue = device.makeCommandQueue() else {
            fatalError("Queue could not be created.")
        }
        
        guard let buffer = queue.makeCommandBuffer() else {
            fatalError("Buffer could not be created.")
        }
        
        // input texture should be a prefilled mixture?
        guard let texture = inputTexture ?? createBaseTexture(device) else {
            fatalError("Could not create texture.")
        }
        
        let timeBuffer = device.makeBuffer(length: MemoryLayout<Float>.size)
        
        // Update time for animation
        // "60fps"
        time += 0.016
        timeBuffer?.contents().storeBytes(of: time, as: Float.self)
        
        // Create new output texture from current input
        guard let nextOutput = outputTexture ?? device.makeSimilarTexture(texture) else {
            fatalError("Could not create output texture.")
        }
        
        effects[effect]?.encode(
            EffectsPayload(
                render: render,
                buffer: buffer,
                inputTexture: texture,
                outputTexture: nextOutput,
                sample: time,
                time: time
            )
        )
        
        buffer.waitUntilCompleted()
        
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
        (device ?? context.device)?.makeTexture(descriptor: createDescriptor())
    }
}

extension MTLDevice {
    func makeSimilarTexture(_ texture: MTLTexture) -> MTLTexture? {
        self.makeTexture(descriptor: texture.descriptor2D)
    }
}

extension MTLTexture {
    var descriptor2D: MTLTextureDescriptor {
        let descriptor: MTLTextureDescriptor = .texture2DDescriptor(
            pixelFormat: self.pixelFormat,
            width: self.width,
            height: self.height,
            mipmapped: self.mipmapLevelCount > 1
        )
        descriptor.usage = self.usage
        descriptor.storageMode = self.storageMode
        return descriptor
    }
}
