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
    }
    
    let context: MetalContext
    var effects: [Engine.Catalogue: Effect]
    
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
            .whirl : Whirl(context)
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
        guard let texture = createBaseTexture(device) else {
            fatalError("Could not create texture.")
        }
        
        // Load the whirl kernel from context.library
        guard let whirlKernel = context.library?.makeFunction(name: "whirl") else {
            fatalError("Could not find whirl kernel.")
        }
        
        let timeBuffer = device.makeBuffer(length: MemoryLayout<Float>.size)
        
        var currentInput = texture
        var time: Float = 0.0
        
        while true {
            // Update time for animation
            // "60fps"
            time += 0.016
            timeBuffer?.contents().storeBytes(of: time, as: Float.self)
            
            // Create new output texture from current input
            guard let nextOutput = device.makeSimilarTexture(currentInput) else {
                fatalError("Could not create output texture.")
            }
            
            effects[effect]?
                .encode(
                    render,
                    inputTexture: currentInput,
                    outputTexture: nextOutput,
                    sample: time
                )
            
            
            buffer.waitUntilCompleted()
            
            // Swap for next iteration
            currentInput = nextOutput
        }
        
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
        .texture2DDescriptor(
            pixelFormat: self.pixelFormat,
            width: self.width,
            height: self.height,
            mipmapped: self.mipmapLevelCount > 1
        )
    }
}
