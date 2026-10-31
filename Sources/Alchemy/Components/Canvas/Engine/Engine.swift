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
        
        let encoder = buffer.makeComputeCommandEncoder()
        
        
        buffer.waitUntilCompleted()
        
    }
}
