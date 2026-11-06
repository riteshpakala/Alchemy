//
//  MetalModel.swift
//  Alchemy
//
//  Created by Ritesh Pakala Rao on 10/31/26.
//

import Foundation
import MetalKit
import Granite

final class MetalModel: GraniteModel, @unchecked Sendable {
    static func == (lhs: MetalModel, rhs: MetalModel) -> Bool {
        // Compare by render identity since textures are ephemeral
        return ObjectIdentifier(lhs.engine) == ObjectIdentifier(rhs.engine)
    }
    // TODO: should the engine be in the model?
    let engine: Engine
    
    init(context: MetalContext) {
        self.engine = Engine(context: context)
    }
    
    // Don't need it to conform to decoder/encoder because Canvas won't need to persist state to the disk.
    // Just need equatable to process view updates.
    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) not implemented")
    }
    func encode(to encoder: any Encoder) throws {
        fatalError("encode(to:) not implemented")
    }
}
