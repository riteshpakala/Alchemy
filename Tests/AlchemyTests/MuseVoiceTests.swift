//
//  MuseVoiceTests.swift
//  AlchemyTests
//
//  WHAT: Words become samples: 24 kHz mono, about as long as the words take to
//        say, never clipped, and the same samples for the same seed.
//  OUT:  MuseVoice (the voice MuseService.Translate speaks with)
//  PIN:  Needs the voice's files (git lfs pull): a checkout without them fails
//        here rather than passing with nothing checked.
//

import Foundation
import Testing
@testable import Alchemy

@Suite(.serialized) struct MuseVoiceTests {

    @Test func theResourcesAreThere() throws {
        _ = try #require(MuseVoiceAssets.directory(), "Resources/Voice, with real files (git lfs pull)")
    }

    @Test func wordsBecomeSamples() async throws {
        let voice = MuseVoice()
        let rendered = try await voice.samples(
            for: "In the quiet of the evening, Arjuna asked a question.", seed: 7)
        #expect(rendered.sampleRate == 24_000)
        #expect(rendered.seconds > 1.5 && rendered.seconds < 8, "\(rendered.seconds) s")
        #expect((rendered.samples.map(abs).max() ?? 0) > 0.1, "it speaks")
        #expect((rendered.samples.map(abs).max() ?? 1) <= 0.951, "and the limiter holds")
    }

    @Test func theSameSeedIsTheSameRender() async throws {
        let voice = MuseVoice()
        let text = "Two sentences, one render. The second follows a pause."
        let first = try await voice.samples(for: text, seed: 42)
        let second = try await voice.samples(for: text, seed: 42)
        #expect(first.samples == second.samples)
    }
}
