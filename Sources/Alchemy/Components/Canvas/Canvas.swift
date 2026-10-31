import Granite

/// Loads a metal service for rendering shaders
struct Canvas: GraniteComponent {
    @Command var center: Center
    @Relay var service: MetalService
    @Relay(.silence) var muse: MuseService
}
