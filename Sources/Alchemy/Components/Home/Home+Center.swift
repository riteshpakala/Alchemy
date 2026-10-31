import Granite
import SwiftUI

extension Home {
    public struct Center: GraniteCenter {
        public struct State: GraniteState {
            /// What is being written in the words patch.
            var draft: String = ""
            /// The last words sent to translate: until MuseService's samples
            /// are of these words, they are still being stitched.
            var requested: String?

            public init () {}
        }
        
        @Store public var state: State
        
        public init () {}
    }
}
