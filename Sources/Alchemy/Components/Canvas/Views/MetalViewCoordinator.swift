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
    var frame: Int = 0
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView,
                 drawableSizeWillChange size: CGSize) {
        // The view's drawable size is now set; we can use it for any size-dependent setup
        // MTKView handles texture creation internally based on this size
        print("MetalViewCoordinator: drawable size will change to \(size)")
    }
    
    func draw(in view: MTKView) {
        guard let model else { return }
        
        // Cycle the frame counter 0–60, resetting after 60
        frame = (frame + 1) % 61
        
        // Compute a sample index into render.samples based on the frame
        // This cycles through the audio samples as the frame advances
        let sampleIndex: Int
        if let render {
            sampleIndex = frame % max(1, render.samples.count)
        } else {
            sampleIndex = 0
        }
        
        // Normalize frame to 0.0–1.0 range for shader time variable
        let normalizedFrame = Float(frame) / 60.0
        
        // Process the render through the engine with the frame counter as the time variable
        if let render {
            model.engine.process(
                render,
                drawable: view.currentDrawable,
                frame: frame,
                sampleValue: Float(render.samples[sampleIndex])
            )
        }
        
        // Present the drawable to the screen — this is what was missing
        // MTKViewDrawable has a present() method
        view.currentDrawable?.present()
        
        print("Frame: \(frame), Sample: \(sampleIndex), Value: \(sampleIndex > 0 && sampleIndex < (render?.samples.count ?? 1) ? String(render!.samples[sampleIndex]) : "N/A")")
    }
}
