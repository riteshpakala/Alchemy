import Granite
import SwiftUI

extension Canvas {
    struct Center: GraniteCenter {
        struct State: GraniteState {
            var model: MetalModel = .init(
                render: MuseVoice.Rendered(samples: [], sampleRate: 24000),
                context: MetalContext(MetalViewCoordinator())
            )
        }
        
        @Store public var state: State
    }
}
