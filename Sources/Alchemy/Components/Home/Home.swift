import Granite

public struct Home: GraniteComponent {
    @Command public var center: Center
    @Relay var muse: MuseService
    
    public init() {}
}
