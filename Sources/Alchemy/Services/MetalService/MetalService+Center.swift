import Granite
import SwiftUI

extension MetalService {
    struct Center: GraniteCenter {
        struct State: GraniteState {
            
        }
        
        @Store(
            persist: "alchemy.metal.persistence.0000",
            autoSave: true,
            preload: true
        ) public var state: State
    }
}
