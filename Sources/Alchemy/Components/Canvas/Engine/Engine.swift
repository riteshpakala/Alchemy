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
    
    // TODO: load the effect kernels into a catalogue of options
    
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
        
        guard let encoder = buffer.makeComputeCommandEncoder() else {
            fatalError("Could not create command encoder.")
        }
        
        // Load the whirl kernel from context.library
        guard let whirlKernel = context.library?.makeFunction(name: "whirl") else {
            fatalError("Could not find whirl kernel.")
        }
        
        guard let pipelineState = try? device.makeComputePipelineState(function: whirlKernel) else {
            fatalError("Could not create pipeline state.")
        }
        
        // Create two float buffers: sample and time
        let sampleBuffer = device.makeBuffer(length: MemoryLayout<Float>.size)
        let timeBuffer = device.makeBuffer(length: MemoryLayout<Float>.size)
        
        var mutableSample: Float = 1.0
        var mutableTime: Float = 0.0
        
        // Store the float values into the mtlbuffers directly
        sampleBuffer?.contents().storeBytes(of: mutableSample, as: Float.self)
        timeBuffer?.contents().storeBytes(of: mutableTime, as: Float.self)
        
        encoder.setComputePipelineState(pipelineState)
        encoder.setTexture(texture, index: 0)
        encoder.setTexture(outputTexture, index: 1)
        encoder.setBuffer(sampleBuffer, offset: 0, index: 0)
        encoder.setBuffer(timeBuffer, offset: 0, index: 1)
        
        let width = texture.width
        let height = texture.height
        
        encoder.dispatchThreadgroups(
            .init(width: (width + 15) / 16, height: (height + 15) / 16, depth: 1),
            threadsPerThreadgroup: .init(width: min(16, width), height: min(16, height), depth: 1)
        )
        
        encoder.endEncoding()
        
        buffer.commit()
        buffer.waitUntilCompleted()
        
        // Swap output to input for the next frame and loop with a timer
        var currentInput = texture
        var currentOutput = outputTexture
        var time: Float = 0.0
        
        while true {
            // Update time for animation
            time += 0.016
            timeBuffer?.contents().storeBytes(of: time, as: Float.self)
            
            // Create new output texture from current input
            guard let nextOutput = device.makeSimilarTexture(currentInput) else {
                fatalError("Could not create output texture.")
            }
            
            guard let encoder = buffer.makeComputeCommandEncoder() else {
                fatalError("Could not create command encoder.")
            }
            
            encoder.setComputePipelineState(pipelineState)
            encoder.setTexture(currentInput, index: 0)
            encoder.setTexture(nextOutput, index: 1)
            encoder.setBuffer(sampleBuffer, offset: 0, index: 0)
            encoder.setBuffer(timeBuffer, offset: 0, index: 1)
            
            encoder.dispatchThreadgroups(
                .init(width: (currentInput.width + 15) / 16, height: (currentInput.height + 15) / 16, depth: 1),
                threadsPerThreadgroup: .init(width: min(16, currentInput.width), height: min(16, currentInput.height), depth: 1)
            )
            
            encoder.endEncoding()
            buffer.commit()
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
