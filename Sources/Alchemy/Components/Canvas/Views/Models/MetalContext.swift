//
//  MetalContext.swift
//  Alchemy
//
//  Created by Ritesh Pakala Rao on 10/31/26.
//

import Foundation
import MetalKit

class MetalContext {
    let device: MTLDevice?
    let coordinator: MetalViewCoordinator
    
    init(_ coordinator: MetalViewCoordinator) {
        self.device = MTLCreateSystemDefaultDevice()
        self.coordinator = coordinator
    }
}
