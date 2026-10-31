//
//  MuseVoiceAssets.swift
//  Alchemy
//
//  WHAT: Where the voice's files are: the models, the phoneme vocabulary, the
//        lexicons and the G2P (Resources/Voice, copied whole into the bundle).
//  IN:   MuseVoice.load
//  OUT:  the Voice directory, or nil when the resources are missing
//  PIN:  The app bundle and the binary's folder first, `Bundle.module` last
//        and never inside an .app: its generated accessor traps unless the
//        bundle sits at the .app's root or at the absolute .build path of the
//        Mac that built it (Ambient's KokoroAssets, the same lesson).
//  PIN:  The models and lexicons are git lfs files. A checkout without
//        `git lfs pull` holds pointers, and the directory reads as missing.
//

import Foundation

enum MuseVoiceAssets {

    static let bundleName = "Alchemy_Alchemy.bundle"
    static let folder = "Voice"

    static func directory() -> URL? {
        for url in candidates() where looksValid(url) {
            return url
        }
        guard Bundle.main.bundleURL.pathExtension != "app" else { return nil }
        if let url = Bundle.module.url(forResource: folder, withExtension: nil), looksValid(url) {
            return url
        }
        return nil
    }

    /// Contents/Resources of a packaged app first, then beside the binary —
    /// where `swift build` and `swift run` leave the bundle.
    static func candidates() -> [URL] {
        var roots: [URL] = []
        if let resources = Bundle.main.resourceURL { roots.append(resources) }
        if let executable = Bundle.main.executableURL?.deletingLastPathComponent() {
            roots.append(executable)
        }
        return roots.flatMap { root in
            [
                root.appendingPathComponent("\(bundleName)/\(folder)"),
                root.appendingPathComponent("\(bundleName)/Contents/Resources/\(folder)"),
            ]
        }
    }

    /// The vocabulary, both stages of the model, and a real (not pointer) weight file.
    static func looksValid(_ dir: URL) -> Bool {
        let fm = FileManager.default
        guard fm.fileExists(atPath: dir.appendingPathComponent("vocab_index.json").path),
              ParadeeBackend.isPresent(in: dir) else { return false }
        let weights = dir.appendingPathComponent("ParadeeAcoustic.mlmodelc/weights/weight.bin")
        let size = (try? fm.attributesOfItem(atPath: weights.path)[.size] as? Int) ?? 0
        return size > 1_000_000
    }
}
