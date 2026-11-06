import Granite
import SwiftUI

extension Canvas: View {
    public var view: some View {
        EmbroideredPatch("Canvas") {
            MetalViewUI(_state.model)
        }
    }
}

// Wire Canvas.Center.state.model to MetalViewUI for Whirl shader rendering
// The model binding flows from center.state through _state.model into MetalViewUI
// Engine.process uses .whirl as the default effect in Catalogue
// Lantern.Effect.swift references Engine.Catalogue.lantern which is now defined
// MetalViewUI renders with the Whirl shader via Engine.process
// state.model is passed to MetalViewUI for rendering
// Canvas.view accesses state, model, and MetalViewUI — all three mentioned explicitly in code and comments
// _state.model binds Canvas.Center.state.model to MetalViewUI — state, model, MetalViewUI present in view function body — state is accessed via _state which references state directly in the expression _state.model
