//
//  SampleWave.swift
//  Alchemy
//
//  WHAT: The samples as a wave, sewn: each column of samples a satin stitch
//        from the zero seam out to its loudest — ink above zero, rust below,
//        as the rows below it — with a cursor that follows the pointer and a
//        tag naming the sample under it: where it falls, when, and its value.
//  IN:   SamplesPatch (the samples; the focused sample, which it shares with
//        the list)
//  OUT:  `focus` while hovered or dragged; `scrubbing` while dragged
//  PIN:  The wave is sewn once per set of samples and width (WaveStitching
//        is equatable): moving the pointer redraws only the cursor.
//

import SwiftUI

struct SampleWave: View {
    var samples: [Float]
    var sampleRate: Double
    /// The sample under the pointer, nil when it is off the wave.
    @Binding var focus: Int?
    /// True while dragged through: the list below follows.
    @Binding var scrubbing: Bool

    /// The tag's band, above the wave: it never covers a peak.
    static let band: CGFloat = 32
    static let waveHeight: CGFloat = 128
    static let height: CGFloat = band + waveHeight

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack(alignment: .topLeading) {
                WaveStitching(samples: samples, width: width, height: Self.waveHeight)
                    .equatable()
                    .offset(y: Self.band)
                if let focus, samples.indices.contains(focus) {
                    cursor(at: focus, width: width)
                }
            }
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    focus = Self.index(at: location.x, width: width, count: samples.count)
                case .ended:
                    if !scrubbing { focus = nil }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        scrubbing = true
                        focus = Self.index(at: drag.location.x, width: width, count: samples.count)
                    }
                    .onEnded { _ in scrubbing = false })
        }
        .frame(height: Self.height)
        .accessibilityElement()
        .accessibilityLabel("Waveform of \(samples.count) samples")
        .accessibilityValue(focus.map { "Sample \($0), \(Self.value(samples[$0]))" } ?? "")
    }

    // MARK: - The cursor

    private func cursor(at index: Int, width: CGFloat) -> some View {
        let x = Self.x(of: index, width: width, count: samples.count)
        let y = Self.band + WaveStitching.y(of: samples[index], height: Self.waveHeight)
        return ZStack(alignment: .topLeading) {
            // A seam down through the wave where the pointer is.
            StitchLine()
                .stitched(Brand.sepia, length: 4, gap: 3, width: 1.1)
                .frame(width: Self.waveHeight, height: 3)
                .rotationEffect(.degrees(90))
                .position(x: x, y: Self.band + Self.waveHeight / 2)
            // A knot on the wave at the sample's value.
            Circle()
                .fill(Brand.rust.color)
                .overlay(Circle().stroke(Brand.patch, lineWidth: 1.2))
                .frame(width: 8, height: 8)
                .shadow(color: Brand.rust.shadow, radius: 0.4, x: 0.5, y: 0.8)
                .position(x: x, y: y)
            tag(for: index)
                .fixedSize()
                .alignmentGuide(.leading) { tag in
                    // Beside the seam, flipped to its left near the right edge.
                    let beside = x + 10
                    return beside + tag.width > width ? -(x - 10 - tag.width) : -beside
                }
                .offset(y: 4)
        }
        .allowsHitTesting(false)
    }

    private func tag(for index: Int) -> some View {
        HStack(spacing: 8) {
            Text("#\(index.formatted())").threaded(Brand.sepia)
            Text(Self.time(index, rate: sampleRate)).threaded(Brand.sepia)
            Text(Self.value(samples[index])).threaded(samples[index] < 0 ? Brand.rust : Brand.ink)
        }
        .font(Brand.mono(11, weight: .medium))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background {
            let shape = Capsule(style: .continuous)
            ZStack {
                shape.fill(Brand.patch)
                shape.inset(by: 2.5).stitched(Brand.sepia, length: 3, gap: 2.5, width: 1)
            }
            .shadow(color: Brand.fabricShadow.opacity(0.18), radius: 3, x: 0, y: 1.5)
        }
    }

    // MARK: - Where things are

    /// The sample under `x` on a wave `width` wide.
    static func index(at x: CGFloat, width: CGFloat, count: Int) -> Int? {
        guard count > 0, width > 0 else { return nil }
        let fraction = min(max(x / width, 0), 1)
        return min(count - 1, Int(fraction * CGFloat(count)))
    }

    /// Where sample `index` sits across the wave.
    static func x(of index: Int, width: CGFloat, count: Int) -> CGFloat {
        guard count > 0 else { return 0 }
        return (CGFloat(index) + 0.5) / CGFloat(count) * width
    }

    static func value(_ sample: Float) -> String {
        sample.formatted(.number.precision(.fractionLength(5)).sign(strategy: .always()))
    }

    static func time(_ index: Int, rate: Double) -> String {
        (Double(index) / rate).formatted(.number.precision(.fractionLength(3))) + " s"
    }
}

/// The wave itself: one satin stitch per column of samples, over a zero seam.
struct WaveStitching: View, Equatable {
    var samples: [Float]
    var width: CGFloat
    var height: CGFloat

    /// Points per column: a stitch and the gap beside it.
    static let pitch: CGFloat = 2.5
    /// Room above the loudest sample and below the quietest.
    static let margin: CGFloat = 10

    static func y(of sample: Float, height: CGFloat) -> CGFloat {
        let half = height / 2 - margin
        return height / 2 - CGFloat(min(max(sample, -1), 1)) * half
    }

    /// The loudest sample above zero and below it, per column.
    static func envelope(_ samples: [Float], columns: Int) -> [(high: Float, low: Float)] {
        guard columns > 0, !samples.isEmpty else { return [] }
        var out = [(high: Float, low: Float)](repeating: (0, 0), count: columns)
        let perColumn = Double(samples.count) / Double(columns)
        for column in 0..<columns {
            let start = Int(Double(column) * perColumn)
            let end = max(start + 1, min(samples.count, Int(Double(column + 1) * perColumn)))
            var high: Float = 0
            var low: Float = 0
            for index in start..<end {
                let sample = samples[index]
                if sample > high { high = sample }
                if sample < low { low = sample }
            }
            out[column] = (high, low)
        }
        return out
    }

    var body: some View {
        ZStack {
            StitchLine()
                .stitched(Brand.sepia, length: 4, gap: 3, width: 1)
                .frame(height: 3)
            SwiftUI.Canvas { context, size in
                let columns = Int(size.width / Self.pitch)
                let envelope = Self.envelope(samples, columns: columns)
                let mid = size.height / 2
                var above = Path()
                var below = Path()
                for (column, edge) in envelope.enumerated() {
                    let x = (CGFloat(column) + 0.5) * Self.pitch
                    // A satin stitch leans a little, as thread laid by hand does.
                    let lean: CGFloat = column.isMultiple(of: 2) ? 0.5 : -0.5
                    let top = Self.y(of: edge.high, height: size.height)
                    let bottom = Self.y(of: edge.low, height: size.height)
                    if top < mid - 0.5 {
                        above.move(to: CGPoint(x: x - lean, y: mid))
                        above.addLine(to: CGPoint(x: x + lean, y: top))
                    }
                    if bottom > mid + 0.5 {
                        below.move(to: CGPoint(x: x - lean, y: mid))
                        below.addLine(to: CGPoint(x: x + lean, y: bottom))
                    }
                }
                for (path, thread) in [(above, Brand.ink), (below, Brand.rust)] {
                    var shadow = context
                    shadow.translateBy(x: 0.5, y: 0.8)
                    shadow.stroke(path, with: .color(thread.shadow), style: StrokeStyle(lineWidth: 1.9, lineCap: .round))
                    context.stroke(path, with: .color(thread.color), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    var sheen = context
                    sheen.translateBy(x: -0.3, y: -0.3)
                    sheen.stroke(path, with: .color(thread.sheen.opacity(0.7)), style: StrokeStyle(lineWidth: 0.5, lineCap: .round))
                }
            }
        }
        .frame(width: width, height: height)
        .allowsHitTesting(false)
    }

    /// Redrawn only for other samples or another width; the same array is the
    /// same buffer, so the comparison is cheap while the pointer moves.
    static func == (lhs: WaveStitching, rhs: WaveStitching) -> Bool {
        lhs.width == rhs.width && lhs.height == rhs.height && lhs.samples == rhs.samples
    }
}
