//
//  MetalViewCoordinator.swift
//  Alchemy
//
//  Created by Ritesh Pakala Rao on 11/1/26.
//

import MetalKit
import SwiftUI

class MetalViewCoordinator: NSObject, MTKViewDelegate {
    let base = CFAbsoluteTimeGetCurrent()
    var currentTexture: MTLTexture? = nil
    weak var model: MetalModel?
    
    // TODO: Orientation
    func mtkView(_ view: MTKView,
                 drawableSizeWillChange size: CGSize) {
        
    }
    
    // Can use as display link on its own?
    // Sample frame based on 120hz?
    func draw(in view: MTKView) {
        guard let model else { return }
        
        // Process the render through the engine on each frame
        model.engine.process(model.render)
        
        let frame = (Int(CFAbsoluteTimeGetCurrent() - base) % (120 * 10)) / 120
        // 0...1...n...10
        
        print("Frame count: \(frame)")
    }
}
