//
//  MuseVoice.swift
//  Alchemy
//
//  WHAT: Words → 24 kHz mono samples, on this Mac and without playback:
//        Kokoro's front end (normalizer, lexicons, G2P → phoneme ids) over
//        teacher-in-the-loop af_heart on Core ML (ParadeeBackend).
//  IN:   MuseService.Translate
//  OUT:  MuseVoice.Rendered — the samples and their rate
//  PIN:  Ambient's render path (KokoroEngine.render, options .standard, at
//        1cb03fc): the same pieces, edge trims, pauses, filters and level, so a
//        line rendered here is the line Ambient would say.
//  PIN:  Loads once, on first use (~1 s: lexicons, G2P, both stages, and the
//        voice's level measured on three calibration sentences). An actor:
//        one render at a time. Core ML runs on the CPU only — the LSTMs abort
//        on the GPU.
//

import CoreML
import Foundation

/*
 
 Text == BERT encoder, phonemes
 
 Acoustic == Pitch Curve and energy
 
 */


actor MuseVoice {

    struct Rendered: Sendable {
        /// Mono, −1…1, limited to KokoroSeamDSP.ceiling (0.95).
        var samples: [Float]
        var sampleRate: Double
        var seconds: Double { Double(samples.count) / sampleRate }
    }

    private let phonemizer = KokoroPhonemizer()
    private let g2p = KokoroG2P()
    private let options = KokoroOptions.standard
    private var backend: ParadeeBackend?
    /// The voice's one gain (KokoroSeamDSP.gain), measured at load.
    private var gain: Float?
    private var loading: Task<Void, Error>?

    init() {}

    // MARK: - Speaking

    /// `text` as samples. `seed` fixes the voice's noise: the same seed and
    /// text give the same samples; nil draws fresh noise.
    func samples(for text: String, seed: UInt64? = nil) async throws -> Rendered {
        try await load()
        guard let backend else { throw TTSError.modelsNotLoaded }
        var seeds = SeedSequence(seed)
        let phonemes = await phonemizer.phonemizeUnits(text, options: options)
        let pieces = KokoroSegmenter.plan(phonemes).map { segment in
            ([0] + phonemes.ids(segment.range, closeWith: segment.closeWith) + [0], segment.pauseAfter)
        }
        var spoken: [(samples: [Float], pauseAfter: KokoroPause)] = []
        for (piece, pauseAfter) in pieces where piece.count > 2 {
            try Task.checkCancellation()
            // The segmenter cuts well inside the model's window; a run it could not cut is shortened.
            let ids = piece.count > backend.maxTokens ? Array(piece.prefix(backend.maxTokens - 1)) + [0] : piece
            let output = try await backend.run(ids: ids, voice: nil, seed: seeds.next())
            let bounds = KokoroSeamDSP.trimBounds(predDur: output.frames, endsOnMark: endsOnPausingMark(ids))
            let trim = KokoroSeamDSP.trimmed(
                output.samples, sampleRate: backend.sampleRate, leadMax: bounds.lead, tailMax: bounds.tail)
            spoken.append((trim.samples, pauseAfter))
        }
        var waveform = KokoroSeamDSP.joined(spoken, sampleRate: backend.sampleRate)
        KokoroSeamDSP.finish(
            &waveform, sampleRate: backend.sampleRate,
            gain: gain ?? KokoroSeamDSP.gain(loudnessDb: ParadeeBackend.typicalLoudnessDb))
        return Rendered(samples: waveform, sampleRate: backend.sampleRate)
    }

    /// A word said your way, as Kokoro IPA (`ɹɛtˈɛʃ`). Applies to every later render.
    func addPronunciation(_ word: String, ipa: String) async throws {
        try await load()
        phonemizer.addCustomPronunciation(word, ipa: ipa)
    }

    // MARK: - Loading

    /// Idempotent; concurrent callers share one load.
    func load() async throws {
        if backend != nil { return }
        if let loading { return try await loading.value }
        let task = Task { try await self.loadNow() }
        loading = task
        do {
            try await task.value
        } catch {
            loading = nil
            throw error
        }
    }

    private func loadNow() async throws {
        guard let dir = MuseVoiceAssets.directory() else {
            throw TTSError.modelLoadFailed("Resources/Voice is missing or holds git lfs pointers (run `git lfs pull`)")
        }
        let backend = try await ParadeeBackend.load(from: dir) { url in
            try await MLModel.compileModel(at: url)
        }
        try phonemizer.loadVocab(from: dir.appendingPathComponent("vocab_index.json"))
        // First entry wins: American gold, then British, then the silver lists.
        for name in ["us_gold.json", "gb_gold.json", "us_silver.json", "gb_silver.json"] {
            let url = dir.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path) { try phonemizer.loadLexicon(from: url) }
        }
        // The G2P spells words no lexicon has; the cache answers most of them without it.
        try g2p.loadVocab(from: dir.appendingPathComponent("g2p_vocab.json"))
        let cache = dir.appendingPathComponent("us_lexicon_cache.json")
        if FileManager.default.fileExists(atPath: cache.path) { try await g2p.loadLexiconCache(from: cache) }
        try await g2p.loadModels(
            encoderURL: dir.appendingPathComponent("G2PEncoder.mlmodelc"),
            decoderURL: dir.appendingPathComponent("G2PDecoder.mlmodelc"))
        phonemizer.g2p = g2p
        self.backend = backend
        gain = await calibrate(backend)
    }

    /// Sentences the voice is measured on: a greeting, a statement, a clause-y one.
    private static let calibrationSentences = [
        "Hi! It's good to hear from you, and I'm glad you asked.",
        "That sounds like a lovely way to spend a quiet evening at home.",
        "Here's the thing: it depends on what you want, and when you need it.",
    ]

    /// The median voiced loudness of the calibration sentences, as a gain.
    private func calibrate(_ backend: ParadeeBackend) async -> Float? {
        var loudness: [Float] = []
        for (index, text) in Self.calibrationSentences.enumerated() {
            let phonemes = await phonemizer.phonemizeUnits(text, options: options)
            let ids = [0] + phonemes.ids(0..<phonemes.units.count, closeWith: ".") + [0]
            guard let output = try? await backend.run(ids: ids, voice: nil, seed: UInt64(index)) else { continue }
            let level = KokoroSeamDSP.voicedLoudness(output.samples, sampleRate: backend.sampleRate)
            if level.isFinite { loudness.append(level) }
        }
        guard !loudness.isEmpty else { return nil }
        return KokoroSeamDSP.gain(loudnessDb: loudness.sorted()[loudness.count / 2])
    }

    /// The last id before EOS is a mark the model pauses on.
    private func endsOnPausingMark(_ ids: [Int32]) -> Bool {
        guard ids.count >= 2, let mark = phonemizer.markSymbol(for: ids[ids.count - 2]) else { return false }
        return KokoroLexer.pausing.contains(mark)
    }
}

/// One seed per model call: from a fixed seed, a fixed sequence; else fresh each time.
private struct SeedSequence {
    private let base: UInt64?
    private var calls: UInt64 = 0

    init(_ base: UInt64?) { self.base = base }

    mutating func next() -> UInt64 {
        guard let base else { return UInt64.random(in: .min ... .max) }
        defer { calls &+= 1 }
        return base &+ calls &* 0x9E37_79B9
    }
}
