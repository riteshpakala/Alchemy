import Granite

/// Converts words into sound, sound that is used as a visualizer's backbone
/// There is no sound player initially, but the visualization should create this
/// experience that matches the pacing of a reading in Gita's Wish.
struct MuseService: GraniteService {
    @Service var center: Center

    /// Words → samples, on this Mac: teacher-in-the-loop af_heart on Kokoro's
    /// front end (Voice/). Loaded on first use; one render at a time.
    static let voice = MuseVoice()

    /// Translate `text`: words → tts → float sample array. On the main actor,
    /// because a send from another thread races the commit before it.
    @MainActor
    func translate(_ text: String) {
        center.translate.send(Translate.Meta(text: text))
    }
}
