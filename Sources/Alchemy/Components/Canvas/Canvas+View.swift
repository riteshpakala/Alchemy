import Granite
import SwiftUI

extension Canvas: View {
    public var view: some View {
        EmbroideredPatch("Canvas") {
            MetalViewUI(_state.model)
        }
    }
}
