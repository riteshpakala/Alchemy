//
//  EffectKernel.swift
//  Alchemy
//
//  Created by Ritesh Pakala Rao on 10/31/26.
//

import Foundation
import MetalKit

struct EffectKernel {
    var context: MetalContext
    
    var fragmentShaderName: String
    var pipelineFunction: MTLComputePipelineState?
    
    init(context: MetalContext, fragmentShaderName: String) {
        self.context = context
        
        if let pipelineFunction = context.library?.makeFunction(name: "whirl") {
            
            self.pipelineFunction = try? context.device?
                .makeComputePipelineState(
                    function: pipelineFunction
                )
        }
        
        self.fragmentShaderName = fragmentShaderName
    }
}
