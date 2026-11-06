//
//  MetalView.swift
//  Alchemy
//
//  Created by Ritesh Pakala Rao on 10/29/26.
//

import Foundation
import MetalKit

class MetalView: MTKView {
    var context: MetalContext
    
    init(_ coordinator: MetalViewCoordinator) {
        self.context = MetalContext(coordinator)
        super.init(
            frame: .init(origin: .zero, size: .init(width: 600, height: 400)),
            device: context.device
        )
        self.setup()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        self.framebufferOnly = false
        self.translatesAutoresizingMaskIntoConstraints = false
        self.layer?.backgroundColor = .clear
        self.clearColor = .init(red: 0, green: 0, blue: 0, alpha: 0)
        self.delegate = self.context.coordinator
        self.isPaused = false
    }
}


