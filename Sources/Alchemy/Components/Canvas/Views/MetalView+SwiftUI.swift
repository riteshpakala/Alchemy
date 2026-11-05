//
//  MetalView+SwiftUI.swift
//  Alchemy
//
//  Created by Ritesh Pakala Rao on 10/29/26.
//

import Granite
import Foundation
import SwiftUI
import MetalKit

struct MetalViewUI: NSViewRepresentable {
    // Demonstrates the beauty behind Relays
    // Instead of passing into the NSViewRep directly
    // we can declare it directly, reducing parameter
    // declarations in the codebase throughout.
    //
    // We do have a muse relate in the calling component
    // which is MetalView, if we do not want double updates
    // we can (.silence) the parent view's Relay of the same
    // service.
    //
    // In Swift I generally like to reduce as much code space as
    // possible, which means reducing implicit param declarations
    // and model initializations via abstracted model patterns or
    // building systems like Relays.
    @Relay var muse: MuseService
    @State private var view: MetalView?
    
    @Binding var model: MetalModel
    
    init(_ model: Binding<MetalModel>) {
        _model = model
    }
    
    func makeNSView(context: Context) -> some MetalView {
        view = MetalView(context.coordinator)
        
        // TODO: force-unwrap
        return view!
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        context.coordinator.currentTexture = model.texture
    }
    
    func makeCoordinator() -> MetalViewCoordinator {
        MetalViewCoordinator()
    }
}


