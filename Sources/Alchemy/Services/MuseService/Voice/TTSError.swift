//
//  TTSError.swift
//  Alchemy
//
//  WHAT: Why words did not become samples.
//  IN:   MuseVoice, KokoroPhonemizer, ParadeeBackend
//  OUT:  a thrown error with a plain description
//  PIN:  The name and cases are Ambient's (KokoroTTSConfig), so the ported
//        front end and backend compile unchanged; the strings are plain, not
//        localized.
//

import Foundation

enum TTSError: LocalizedError {
    case modelsNotLoaded
    case phonemizationFailed
    case modelLoadFailed(String)
    case predictionFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelsNotLoaded: return "The voice's models are not loaded."
        case .phonemizationFailed: return "The words could not be turned into phonemes."
        case .modelLoadFailed(let detail): return "The voice failed to load: \(detail)"
        case .predictionFailed(let detail): return "The voice failed to speak: \(detail)"
        }
    }
}
