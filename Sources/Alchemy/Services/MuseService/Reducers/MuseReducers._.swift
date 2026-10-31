//
//  MuseReducers.swift
//  Alchemy
//
//  Created by Ritesh Pakala Rao on 10/29/26.
//

import Foundation
import Granite

extension MuseService {
    /// Words to music notation.
    struct Translate: GraniteReducer {
        typealias Center = MuseService.Center


        // words -> tts -> float sample array -> amplitudes -> 10s loop -> Metal canvas
        // translate == words -> tts -> float sample array
        // MetalService
        // generate -> a shader that takes a float buffer param
        // DisplayLink Canvas with a 10s looper
        // loops the shader with the translated amplitudes for 10secs on a MTKView in SwiftUI

        /// The words to translate.
        struct Meta: GranitePayload {
            var text: String
        }

        @Payload var meta: Meta?

        /// The voice takes seconds, so this reducer is a task: Granite runs it in
        /// its own Task, off the main thread, and a new translate cancels the one
        /// in flight. When it returns, Granite writes its copy of the state back.
        var behavior: GraniteReducerBehavior { .task(.userInitiated) }

        func reduce(state: inout Center.State) async {
            guard let text = meta?.text, !text.isEmpty else { return }
            do {
                // words -> tts -> float sample array (no playback)
                let rendered = try await MuseService.voice.samples(for: text)
                let samples: [Float] = rendered.samples      // mono, −1…1
                let sampleRate: Double = rendered.sampleRate // 24 000 Hz

                // -> amplitudes -> 10s loop -> Metal canvas: from here on.
                state.text = text
                state.samples = samples
                state.sampleRate = sampleRate
                state.lastError = nil
            } catch is CancellationError {
                // A newer translate replaced this one.
            } catch {
                state.text = text
                state.samples = []
                state.lastError = error.localizedDescription
            }
        }
    }
}
