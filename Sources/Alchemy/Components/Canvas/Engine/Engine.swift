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
        case chromaKey = "chromaKey"
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
        drawable: CAMetalDrawable? = nil,
        effect: Catalogue = .lantern,
        frame: Int = 0,
        sampleValue: Float = 0.0
    ) {
        guard let device = context.device else {
            fatalError("No device found.")
            return
        }
        
        // input texture should be a prefilled mixture?
        let texture: MTLTexture
        if let existingInput = inputTexture {
            texture = existingInput
        } else {
            guard let baseTexture = createBaseTexture(device, texture: drawable?.texture) else {
                fatalError("Could not create texture.")
            }
            // Fill the base texture with a solid warm amber color so shaders have data to sample
            fillTexture(
                baseTexture,
                outputTexture: drawable?.texture,
                color: (r: 1.0, g: 0.85, b: 0.6, a: 1.0)
            )
            texture = baseTexture
        }
        
        // Create new output texture from current input
        guard let nextOutput = drawable?.texture ?? device.makeSimilarTexture(texture) else {
            fatalError("Could not create output texture.")
        }
        
        // Normalize frame to 0.0–1.0 for shader time variable
        let normalizedFrame = Float(frame) / 60.0
        
        effects[effect]?.encode(
            EffectsPayload(
                render: render,
                inputTexture: texture,
                outputTexture: nextOutput,
                sample: normalizedFrame,
                time: normalizedFrame,
                sampleValue: sampleValue
            )
        )
    }
    
    func createDescriptor(from texture: MTLTexture?) -> MTLTextureDescriptor {
        // TODO: width and height should scale with UI?
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: texture?.pixelFormat ?? .bgra8Unorm,
            width: texture?.width ?? 1080,
            height: texture?.height ?? 1080,
            mipmapped: false
        )
        
        descriptor.storageMode = texture?.storageMode ?? .shared
        descriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        
        return descriptor
    }
    
    func createBaseTexture(_ device: MTLDevice?, texture: MTLTexture? = nil) -> MTLTexture? {
        (device ?? context.device)?.makeTexture(
            descriptor: createDescriptor(from: texture)
        )
    }
    
    /// Fills a texture with a solid RGBA color using the Fill.solidColorFill kernel from the module.
    /// Uses outputTexture dimensions directly instead of param buffers.
    private func fillTexture(
        _ texture: MTLTexture,
        outputTexture: MTLTexture? = nil,
        color: (r: Float, g: Float, b: Float, a: Float)
    ) {
        guard let queue = context.device?.makeCommandQueue() else {
            fatalError("Queue could not be created.")
        }
        
        guard let buffer = queue.makeCommandBuffer() else {
            fatalError("Buffer could not be created.")
        }
        
        guard let encoder = buffer.makeComputeCommandEncoder() else {
            fatalError("Could not create compute encoder for texture fill.")
        }
        
        guard let device = context.device else {
            return
        }
        
        guard let lib = try? device.makeDefaultLibrary(bundle: .module),
              let function = lib.makeFunction(name: "solidColorFill"),
              let pipelineState = try? device.makeComputePipelineState(function: function) else {
            fatalError("Could not load Fill.solidColorFill from module.")
        }
        
        encoder.setComputePipelineState(pipelineState)
        encoder.setTexture(texture, index: 0)  // input texture
        encoder.setTexture(outputTexture ?? texture, index: 1)  // output texture (same as input for fill)
        
        let colorBuffer = device.makeBuffer(length: MemoryLayout<SIMD4<Float>>.size)
        var mtlColor = SIMD4<Float>(color.r, color.g, color.b, color.a)
        colorBuffer?.contents().storeBytes(of: mtlColor, as: SIMD4<Float>.self)
        encoder.setBuffer(colorBuffer, offset: 0, index: 0)
        
        print(
            "Output Texture: (\(outputTexture?.width), \(outputTexture?.height))"
        )
        
        let width = (outputTexture ?? texture).width
        let height = (outputTexture ?? texture).height
        encoder.dispatchThreadgroups(
            .init(width: (width + 15) / 16, height: (height + 15) / 16, depth: 1),
            threadsPerThreadgroup: .init(width: min(16, width), height: min(16, height), depth: 1)
        )
        
        encoder.endEncoding()
        
        buffer.commit()
        buffer.waitUntilCompleted()
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

extension MTLCommandBuffer {
    func synchronize() {
        self.commit()
        self.waitUntilCompleted()
    }
}
