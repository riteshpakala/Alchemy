//
//  Effect.Whirl.swift
//  Alchemy
//
//  Created by Ritesh Pakala Rao on 10/31/26.
//

import SwiftUI
import MetalKit

struct Whirl: Effect {
    var kernel: EffectKernel

    func process(_ render: MuseVoice.Rendered) {
        guard let (device, queue, buffer) = self.initialize() else {
            fatalError("Could not initialize Effect.")
        }
        
        guard let texture = createBaseTexture(device) else {
            fatalError("Could not create texture.")
        }
    }
}
