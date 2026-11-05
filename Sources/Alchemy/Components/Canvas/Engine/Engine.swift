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
    
    let context: MetalContext
    
    init(context: MetalContext) {
        self.context = context
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
    func process(_ render: MuseVoice.Rendered) {
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
        
        let outputTexture = device.makeSimilarTexture(texture)
        
        
        let encoder = buffer.makeComputeCommandEncoder()
        
        
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
        .texture2DDescriptor(
            pixelFormat: self.pixelFormat,
            width: self.width,
            height: self.height,
            mipmapped: self.mipmapLevelCount > 1
        )
    }
}
