//
//  AlchemyApp.swift
//  Alchemy
//
//  Created by Ritesh Pakala Rao on 10/29/26.
//

import Alchemy
import SwiftUI
import Foundation

struct AlchemyApp: App {
    var body: some Scene {
        WindowGroup {
            Home()
                .windowResizeBehavior(.enabled)
                .frame(
                    minWidth: 600,
                    maxWidth: 800,
                    minHeight: 400,
                    maxHeight: 800
                )
        }
    }
}
