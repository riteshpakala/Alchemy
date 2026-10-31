//
//  SampleWaveTests.swift
//  AlchemyTests
//
//  WHAT: The wave answers the pointer with the right sample — every edge
//        included — and sews each column at its loudest above and below zero.
//  OUT:  SampleWave.index / x, WaveStitching.envelope
//

import Foundation
import Testing
@testable import Alchemy

@Suite struct SampleWaveTests {

    @Test func thePointerFindsItsSample() {
        #expect(SampleWave.index(at: 0, width: 600, count: 48_000) == 0)
        #expect(SampleWave.index(at: 600, width: 600, count: 48_000) == 47_999, "the right edge is the last sample")
        #expect(SampleWave.index(at: 300, width: 600, count: 48_000) == 24_000)
        #expect(SampleWave.index(at: -20, width: 600, count: 48_000) == 0, "dragged past the left edge")
        #expect(SampleWave.index(at: 900, width: 600, count: 48_000) == 47_999, "dragged past the right edge")
        #expect(SampleWave.index(at: 10, width: 600, count: 0) == nil)
        #expect(SampleWave.index(at: 10, width: 0, count: 10) == nil)
    }

    @Test func aSamplesPlaceLeadsBackToIt() {
        for count in [7, 600, 48_000] {
            for index in [0, count / 3, count / 2, count - 1] {
                let x = SampleWave.x(of: index, width: 600, count: count)
                #expect(SampleWave.index(at: x, width: 600, count: count) == index, "\(index) of \(count)")
            }
        }
    }

    @Test func eachColumnIsSewnAtItsLoudest() {
        let samples: [Float] = [0.1, -0.4, 0.9, 0.2, /**/ -0.8, -0.1, 0.3, 0.0]
        let envelope = WaveStitching.envelope(samples, columns: 2)
        #expect(envelope.count == 2)
        #expect(envelope[0].high == 0.9 && envelope[0].low == -0.4)
        #expect(envelope[1].high == 0.3 && envelope[1].low == -0.8)
        #expect(WaveStitching.envelope([], columns: 4).isEmpty)
        let silence = WaveStitching.envelope([Float](repeating: 0, count: 100), columns: 10)
        #expect(silence.allSatisfy { $0.high == 0 && $0.low == 0 }, "silence is only the seam")
    }

    @Test func louderIsHigherAndQuieterSitsOnTheSeam() {
        let height: CGFloat = 128
        #expect(WaveStitching.y(of: 0, height: height) == height / 2)
        #expect(WaveStitching.y(of: 1, height: height) == WaveStitching.margin)
        #expect(WaveStitching.y(of: -1, height: height) == height - WaveStitching.margin)
        #expect(WaveStitching.y(of: 3, height: height) == WaveStitching.margin, "clipped to the frame")
    }
}
