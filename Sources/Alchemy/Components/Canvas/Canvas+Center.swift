import Granite
import SwiftUI

extension Canvas {
    struct Center: GraniteCenter {
        struct State: GraniteState {
            var model: MetalModel = .init()
        }
        
        @Store public var state: State
    }
}
