import Granite

/// Converts words into sound, sound that is used as a visualizer's backbone
/// There is no sound player initially, but the visualization should create this
/// experience that matches the pacing of a reading in Gita's Wish.
struct MuseService: GraniteService {
    @Service var center: Center
}
