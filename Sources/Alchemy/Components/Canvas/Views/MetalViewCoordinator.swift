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
    var render: MuseVoice.Rendered?
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView,
                 drawableSizeWillChange size: CGSize) {
        // The view's drawable size is now set; we can use it for any size-dependent setup
        // MTKView handles texture creation internally based on this size
        print("MetalViewCoordinator: drawable size will change to \(size)")
    }
    
    func draw(in view: MTKView) {
        guard let model else { return }
        
        
        // Process the render through the engine on each frame
        if let render {
            model.engine.process(render, drawable: view.currentDrawable)
        }
        
        
        
        // Present the drawable to the screen — this is what was missing
        // MTKViewDrawable has a present() method
        view.currentDrawable?.present()
        
        let frame = (Int(CFAbsoluteTimeGetCurrent() - base) % (120 * 10)) / 120
        print("Frame: \(frame)")
    }
}
