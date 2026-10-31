//
//  SamplesPatch.swift
//  Alchemy
//
//  WHAT: What Translate made of the words: how many samples, how long, how
//        loud; the wave, to hover or drag through (SampleWave); and every
//        sample in order, each with a stitch as long as it is loud (ink above
//        zero, rust below). Dragging through the wave brings its sample into
//        the list; the sample under the pointer is marked in both.
//  IN:   Home, from MuseService's state
//  OUT:  a read-only list
//  PIN:  A second of speech is 24 000 rows: the list is lazy, and a row is
//        two strings and one seam.
//

import SwiftUI

struct SamplesPatch: View {
    var text: String
    var samples: [Float]
    var sampleRate: Double
    var error: String?
    var stitching: Bool

    /// The sample under the pointer on the wave.
    @State private var focus: Int?
    /// The wave is being dragged through: the list follows it.
    @State private var scrubbing = false

    var body: some View {
        EmbroideredPatch("Samples") {
            if stitching {
                note("Stitching…", thread: Brand.sepia)
            } else if let error {
                note(error, thread: Brand.rust)
            } else if samples.isEmpty {
                note("Nothing translated yet. Write a line above.", thread: Brand.sepia)
            } else {
                summary
                SampleWave(samples: samples, sampleRate: sampleRate, focus: $focus, scrubbing: $scrubbing)
                StitchLine().stitched(Brand.sepia, length: 4, gap: 3, width: 1.1)
                    .frame(height: 3)
                ScrollViewReader { list in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 1) {
                            ForEach(0..<samples.count, id: \.self) { index in
                                SampleRow(index: index, value: samples[index], focused: index == focus)
                            }
                        }
                    }
                    .onChange(of: focus) { _, index in
                        guard scrubbing, let index else { return }
                        list.scrollTo(index, anchor: .center)
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        // Another set of samples: the old focus means nothing in it.
        .onChange(of: samples.count) { focus = nil }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("“\(text)”")
                .font(Brand.serif(15))
                .embroidered(Brand.ink)
                .lineLimit(2)
            Text(details)
                .font(Brand.mono(11))
                .threaded(Brand.sepia)
        }
    }

    private var details: String {
        let seconds = Double(samples.count) / sampleRate
        let peak = samples.reduce(Float(0)) { max($0, abs($1)) }
        return "\(samples.count.formatted()) samples · "
            + seconds.formatted(.number.precision(.fractionLength(2))) + " s · "
            + (sampleRate / 1000).formatted() + " kHz · peak "
            + Double(peak).formatted(.number.precision(.fractionLength(3)))
    }

    private func note(_ line: String, thread: Brand.Thread) -> some View {
        Text(line)
            .font(Brand.serif(14))
            .embroidered(thread)
    }
}

/// One sample: where it falls, its value, and a stitch as long as it is loud.
struct SampleRow: View {
    var index: Int
    var value: Float
    /// Under the pointer on the wave.
    var focused = false

    var body: some View {
        HStack(spacing: 12) {
            Text(index.formatted())
                .frame(width: 70, alignment: .trailing)
                .threaded(Brand.sepia)
            Text(value.formatted(.number.precision(.fractionLength(5)).sign(strategy: .always())))
                .frame(width: 84, alignment: .trailing)
                .threaded(Brand.ink)
            StitchLine()
                .stitched(value < 0 ? Brand.rust : Brand.ink, length: 3, gap: 2, width: 1.1)
                .frame(width: max(2, CGFloat(abs(value)) * 220), height: 3)
            Spacer(minLength: 0)
        }
        .font(Brand.mono(11))
        .padding(.vertical, 1)
        .background {
            if focused {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Brand.weave.opacity(0.28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .inset(by: 1.5)
                            .stitched(Brand.rust, length: 3, gap: 2, width: 0.9))
            }
        }
    }
}
