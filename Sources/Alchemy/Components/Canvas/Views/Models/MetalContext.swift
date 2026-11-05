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
    let library: MTLLibrary?
    let coordinator: MetalViewCoordinator
    
    init(_ coordinator: MetalViewCoordinator) {
        let device = MTLCreateSystemDefaultDevice()
        self.device = device
        self.library = try? device?.makeDefaultLibrary(bundle: .module)
        self.coordinator = coordinator
    }
}
