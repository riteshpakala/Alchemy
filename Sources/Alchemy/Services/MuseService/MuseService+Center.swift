import Granite
import SwiftUI

extension MuseService {
    struct Center: GraniteCenter {
        struct State: GraniteState {
            /// The words the samples are.
            var text: String = ""
            /// What the voice made of them: mono, −1…1. Empty until a translate lands.
            var samples: [Float] = []
            var sampleRate: Double = 24_000
            /// Why the last translate made nothing.
            var lastError: String?
        }
        
        @Event var translate: Translate.Reducer

        @Store public var state: State
    }
}
