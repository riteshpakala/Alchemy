//
//  MetalModel.swift
//  Alchemy
//
//  Created by Ritesh Pakala Rao on 10/31/26.
//

import Foundation
import MetalKit
import Granite

struct MetalModel: @unchecked Sendable, GraniteModel {
    static func == (lhs: MetalModel, rhs: MetalModel) -> Bool {
        if lhs.texture != nil && rhs.texture != nil {
            return ObjectIdentifier(lhs.texture!) == ObjectIdentifier(rhs.texture!)
        } else {
            return lhs.texture == nil && rhs.texture == nil
        }
    }
    
    var texture: MTLTexture?
    
    init() {
        texture = nil
    }
    
    // Don't need it to conform to decoder/encoder because Canvas won't need to persist state to the disk.
    // Just need equatable to process view updates.
    init(from decoder: any Decoder) throws {}
    func encode(to encoder: any Encoder) throws {}
}
