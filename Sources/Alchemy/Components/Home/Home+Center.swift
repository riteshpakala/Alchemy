import Granite
import SwiftUI

extension Home {
    public struct Center: GraniteCenter {
        public struct State: GraniteState {
            public init () {}
        }
        
        @Store public var state: State
        
        public init () {}
    }
}
