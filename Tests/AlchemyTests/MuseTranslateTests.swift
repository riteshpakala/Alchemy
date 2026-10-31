//
//  MuseTranslateTests.swift
//  AlchemyTests
//
//  WHAT: Translate, end to end through Granite: words sent on the main actor,
//        the task reducer speaks them, and MuseService's state holds the samples.
//  OUT:  MuseService.translate → Translate (.task) → state
//

import Foundation
import Granite
import Testing
@testable import Alchemy

@MainActor final class MuseTestRoot {
    @Relay var muse: MuseService
}

@MainActor @Suite(.serialized) struct MuseTranslateTests {

    @Test func translateLeavesTheSamplesInState() async throws {
        let root = MuseTestRoot()
        let text = "Words, stitched into sound."
        root.muse.translate(text)
        let deadline = Date().addingTimeInterval(20)
        while root.muse.state.text != text, Date() < deadline {
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        #expect(root.muse.state.text == text)
        #expect(root.muse.state.lastError == nil)
        #expect(root.muse.state.sampleRate == 24_000)
        #expect(root.muse.state.samples.count > 24_000, "about two seconds of speech")
    }
}
