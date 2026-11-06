import Granite
import SwiftUI

extension Canvas {
    struct Center: GraniteCenter {
        struct State: GraniteState {
            var model: MetalModel = .init(
                context: MetalContext(MetalViewCoordinator())
            )
        }
        
        @Store public var state: State
    }
}
