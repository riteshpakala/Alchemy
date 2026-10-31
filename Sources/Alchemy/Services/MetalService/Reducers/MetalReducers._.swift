//  
//  MuseReducers.swift
//  Alchemy
//
//  Created by Ritesh Pakala Rao on 10/29/26.
//

import Granite

extension MetalService {
    /// Texture draw. Music notation to texture map.
    struct Translate: GraniteReducer {
        typealias Center = MetalService.Center

        func reduce(state: inout Center.State) {
            
        }

        // Optional: declare follow-up work to run after this reducer commits — chain a sibling
        // reducer, or run async side effects — using the effect DSL.
        // func effect(state: Center.State) -> GraniteEffect {
        //     .none
        // }
    }
}
